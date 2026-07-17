import Foundation
import SwiftData

/// Das Herzstück der App: ein Rezept mit allen Angaben.
///
/// Wichtige SwiftData-Regeln, die hier eingehalten werden:
/// - `inverse:` wird pro Beziehung nur auf **einer** Seite deklariert
///   (hier auf der Rezept-Seite; die Gegenseite hat eine einfache Property).
/// - SwiftData speichert Arrays **unsortiert** — deshalb haben Zutaten,
///   Schritte und Bilder einen `sortIndex` und es gibt `sorted…`-Properties.
@Model
final class Recipe {

    // MARK: Grunddaten

    var title: String = ""
    var servings: Int = 4

    /// Zeiten in Minuten. `nil` = keine Angabe.
    var prepMinutes: Int?
    var cookMinutes: Int?
    /// Ruhezeit (Teig gehen lassen, Fleisch ruhen lassen …).
    var restMinutes: Int?

    /// Schwierigkeit als Rohwert gespeichert — robust für SwiftData.
    /// Zugriff im Code über die berechnete Property `difficulty`.
    var difficultyRaw: Int = Difficulty.medium.rawValue

    /// Bewertung 0–5 Sterne (0 = noch nicht bewertet).
    var rating: Int = 0
    var isFavorite: Bool = false

    /// Für welche Mahlzeiten das Rezept im Wochenplan geeignet ist –
    /// gespeichert als Bitmaske (siehe `MealType.bit`). 0 = keine Angabe
    /// („passt überall“). Einfacher Int → unproblematisch für CloudKit.
    var mealTypeMask: Int = 0

    var notes: String = ""

    /// Quelle als Freitext („Omas Kochbuch, S. 12“).
    var sourceText: String = ""
    /// Quelle als Link (bei Web-Importen automatisch gefüllt).
    var sourceURLString: String = ""

    // MARK: Verwaltungsdaten

    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now
    /// Wird vom Kochmodus gesetzt, wenn ein Rezept fertig gekocht wurde.
    var lastCookedAt: Date?
    /// Markiert mitgelieferte Beispielrezepte — nur diese werden beim
    /// „Beispielrezepte neu laden“ in den Einstellungen ersetzt.
    var isSample: Bool = false

    // MARK: Beziehungen

    /// Kategorie/Unterkategorie. Die `inverse`-Deklaration liegt auf der
    /// Kategorie-Seite (`RecipeCategory.recipes`).
    var category: RecipeCategory?
    var subcategory: RecipeSubcategory?

    // Hinweis: Alle To-many-Beziehungen sind OPTIONAL (`[T]?`). Das ist
    // eine zwingende Voraussetzung für die iCloud-Synchronisierung
    // (CloudKit verlangt, dass jede Beziehung optional ist). Der Zugriff
    // erfolgt überall über die `sorted…`-Helfer unten, die immer ein
    // normales Array liefern.
    @Relationship(deleteRule: .cascade, inverse: \Ingredient.recipe)
    var ingredients: [Ingredient]?

    @Relationship(deleteRule: .cascade, inverse: \RecipeStep.recipe)
    var steps: [RecipeStep]?

    @Relationship(deleteRule: .cascade, inverse: \RecipeImage.recipe)
    var images: [RecipeImage]?

    /// Tags sind eine n:m-Beziehung — ein Tag kann an vielen Rezepten hängen.
    @Relationship(inverse: \RecipeTag.recipes)
    var tags: [RecipeTag]?

    /// Fachdaten für Wurst- und Räucherrezepte. Bei normalen Rezepten `nil`.
    @Relationship(deleteRule: .cascade, inverse: \SausageSmokingDetails.recipe)
    var sausageDetails: SausageSmokingDetails?

    /// Einträge im Wochenplan, die dieses Rezept verwenden. Wird das Rezept
    /// gelöscht, verschwinden auch seine Planeinträge (cascade). Optional
    /// wegen CloudKit.
    @Relationship(deleteRule: .cascade, inverse: \PlannedMeal.recipe)
    var plannedMeals: [PlannedMeal]?

    /// Datierte Koch-Notizen („Kochjournal“). Optional wegen CloudKit.
    @Relationship(deleteRule: .cascade, inverse: \CookingNote.recipe)
    var cookingNotes: [CookingNote]?

    // MARK: Init

    init(title: String) {
        self.title = title
    }

    // MARK: Berechnete Werte

    var difficulty: Difficulty {
        get { Difficulty(rawValue: difficultyRaw) ?? .medium }
        set { difficultyRaw = newValue.rawValue }
    }

    /// Gesamtzeit aus allen Teilzeiten (0, wenn nichts angegeben ist).
    var totalMinutes: Int {
        (prepMinutes ?? 0) + (cookMinutes ?? 0) + (restMinutes ?? 0)
    }

    var sortedIngredients: [Ingredient] {
        (ingredients ?? []).sorted { $0.sortIndex < $1.sortIndex }
    }

    var sortedSteps: [RecipeStep] {
        (steps ?? []).sorted { $0.sortIndex < $1.sortIndex }
    }

    var sortedImages: [RecipeImage] {
        (images ?? []).sorted { $0.sortIndex < $1.sortIndex }
    }

    /// Koch-Notizen, neueste zuerst.
    var sortedCookingNotes: [CookingNote] {
        (cookingNotes ?? []).sorted { $0.date > $1.date }
    }

    /// Die Bilddaten des Titelbilds (erstes Bild), falls vorhanden.
    var coverImageData: Data? {
        sortedImages.first?.data
    }

    var sourceURL: URL? {
        guard !sourceURLString.isEmpty else { return nil }
        return URL(string: sourceURLString)
    }

    /// Alle Tag-Namen, alphabetisch — für Anzeige und Suche.
    var tagNames: [String] {
        (tags ?? []).map(\.name).sorted()
    }

    // MARK: Mahlzeit-Eignung (Wochenplan)

    /// Die Mahlzeiten, für die das Rezept ausdrücklich geeignet ist.
    var suitableMealTypes: [MealType] {
        get { MealType.allCases.filter { mealTypeMask & $0.bit != 0 } }
        set { mealTypeMask = newValue.reduce(0) { $0 | $1.bit } }
    }

    /// `true`, wenn der Nutzer überhaupt eine Eignung festgelegt hat.
    var hasMealTypePreference: Bool {
        mealTypeMask != 0
    }

    /// Ist das Rezept ausdrücklich für diese Mahlzeit markiert?
    func isSuitable(for type: MealType) -> Bool {
        mealTypeMask & type.bit != 0
    }

    /// Alle Zutaten ungeordnet — Komfort für Suche/Filter (immer ein Array).
    var ingredientList: [Ingredient] {
        ingredients ?? []
    }
}
