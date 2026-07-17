import Foundation
import Observation

/// Eine Zutaten-Zeile im Editor (Mengen als Text, damit die Eingabe
/// flüssig bleibt — geparst wird erst beim Speichern).
struct DraftIngredient: Identifiable {
    let id = UUID()
    var amountText = ""
    var unit = ""
    var name = ""

    var isEmpty: Bool {
        amountText.trimmingCharacters(in: .whitespaces).isEmpty
            && unit.trimmingCharacters(in: .whitespaces).isEmpty
            && name.trimmingCharacters(in: .whitespaces).isEmpty
    }
}

/// Eine Schritt-Zeile im Editor.
struct DraftStep: Identifiable {
    let id = UUID()
    var text = ""
    /// Timer in Minuten als Text, Komma erlaubt („1,5“ = 90 Sekunden).
    var timerMinutesText = ""

    var isEmpty: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

/// Die bearbeitbare Arbeitskopie eines Rezepts — das Herzstück von
/// Editor und Import.
///
/// Warum kein direktes Bearbeiten des SwiftData-Objekts?
/// - **Abbrechen ist immer gefahrlos**: Der Draft wird einfach verworfen,
///   das gespeicherte Rezept bleibt unberührt.
/// - **Alle Import-Wege münden hier**: `init(parsed:)` macht aus jedem
///   Import-Ergebnis einen vorbefüllten Editor.
/// - **Keine SwiftData-Stolperfallen** mit ungespeicherten Objekten.
///
/// Gespeichert wird zentral über `RecipeImportService.save(draft:…)`.
@MainActor
@Observable
final class RecipeDraft {

    // MARK: Grunddaten

    var title = ""
    var category: RecipeCategory?
    var subcategory: RecipeSubcategory?
    var servings = 4

    /// Zeiten als Text (nur Ziffern), leer = keine Angabe.
    var prepMinutesText = ""
    var cookMinutesText = ""
    var restMinutesText = ""

    var difficulty: Difficulty = .medium
    var rating = 0
    var isFavorite = false
    var notes = ""
    var sourceText = ""
    var sourceURLText = ""
    var tagNames: [String] = []
    var imageDatas: [Data] = []

    /// Für welche Mahlzeiten das Rezept im Wochenplan geeignet ist.
    var suitableMealTypes: Set<MealType> = []

    var ingredients: [DraftIngredient] = [DraftIngredient()]
    var steps: [DraftStep] = [DraftStep()]

    // MARK: Fachdaten Wurst & Räuchern

    /// Blendet den Fachdaten-Abschnitt im Editor ein. Wird bei der
    /// Kategorie „Wurst & Räuchern“ automatisch aktiviert.
    var includeSausageDetails = false

    var meatWeightText = ""
    var seasoningPerKg = ""
    var npsText = ""
    var cutterAids = ""
    var iceWaterText = ""
    var casing = ""
    var smokingMethod: SmokingMethod = .none
    var smokingTimeText = ""
    var smokingTempText = ""
    var scaldingTempText = ""
    var coreTempText = ""
    var curingDaysText = ""
    var dryingDaysText = ""
    var safetyNotes = ""

    // MARK: Inits

    /// Leerer Draft für „Neues Rezept“.
    init() {}

    /// Draft zum Bearbeiten eines bestehenden Rezepts.
    init(recipe: Recipe) {
        title = recipe.title
        category = recipe.category
        subcategory = recipe.subcategory
        servings = recipe.servings
        prepMinutesText = recipe.prepMinutes.map(String.init) ?? ""
        cookMinutesText = recipe.cookMinutes.map(String.init) ?? ""
        restMinutesText = recipe.restMinutes.map(String.init) ?? ""
        difficulty = recipe.difficulty
        rating = recipe.rating
        isFavorite = recipe.isFavorite
        notes = recipe.notes
        sourceText = recipe.sourceText
        sourceURLText = recipe.sourceURLString
        tagNames = recipe.tagNames
        imageDatas = recipe.sortedImages.map(\.data)
        suitableMealTypes = Set(recipe.suitableMealTypes)

        let existingIngredients = recipe.sortedIngredients.map { ingredient in
            var draft = DraftIngredient()
            draft.amountText = FormatHelpers.amountText(ingredient.amount) ?? ""
            draft.unit = ingredient.unit
            draft.name = ingredient.name
            return draft
        }
        ingredients = existingIngredients.isEmpty ? [DraftIngredient()] : existingIngredients

        let existingSteps = recipe.sortedSteps.map { step in
            var draft = DraftStep()
            draft.text = step.text
            if let seconds = step.timerSeconds, seconds > 0 {
                draft.timerMinutesText = FormatHelpers.amountText(Double(seconds) / 60) ?? ""
            }
            return draft
        }
        steps = existingSteps.isEmpty ? [DraftStep()] : existingSteps

        if let details = recipe.sausageDetails {
            includeSausageDetails = true
            meatWeightText = FormatHelpers.amountText(details.meatWeightKg) ?? ""
            seasoningPerKg = details.seasoningPerKg
            npsText = FormatHelpers.amountText(details.npsGramsPerKg) ?? ""
            cutterAids = details.cutterAids
            iceWaterText = FormatHelpers.amountText(details.iceWaterPercent) ?? ""
            casing = details.casing
            smokingMethod = details.smokingMethod
            smokingTimeText = details.smokingTimeMinutes.map(String.init) ?? ""
            smokingTempText = details.smokingTemperatureCelsius.map(String.init) ?? ""
            scaldingTempText = details.scaldingTemperatureCelsius.map(String.init) ?? ""
            coreTempText = details.coreTemperatureCelsius.map(String.init) ?? ""
            curingDaysText = details.curingDays.map(String.init) ?? ""
            dryingDaysText = details.dryingDays.map(String.init) ?? ""
            safetyNotes = details.safetyNotes
        }
    }

    /// Draft aus einem Import-Ergebnis — öffnet den Editor vorbefüllt.
    init(parsed: ParsedRecipe) {
        title = parsed.title
        servings = parsed.servings ?? 4
        prepMinutesText = parsed.prepMinutes.map(String.init) ?? ""
        cookMinutesText = parsed.cookMinutes.map(String.init) ?? ""
        notes = parsed.notes
        sourceText = parsed.sourceText
        sourceURLText = parsed.sourceURLString
        tagNames = parsed.tags
        if let imageData = parsed.imageData {
            imageDatas = [imageData]
        }

        let parsedIngredients = parsed.ingredients.map { parsedIngredient in
            var draft = DraftIngredient()
            draft.amountText = FormatHelpers.amountText(parsedIngredient.amount) ?? ""
            draft.unit = parsedIngredient.unit
            draft.name = parsedIngredient.name
            return draft
        }
        ingredients = parsedIngredients.isEmpty ? [DraftIngredient()] : parsedIngredients

        let parsedSteps = parsed.steps.map { text in
            var draft = DraftStep()
            draft.text = text
            return draft
        }
        steps = parsedSteps.isEmpty ? [DraftStep()] : parsedSteps
    }

    // MARK: Bedienlogik

    /// Speichern ist nur mit Titel erlaubt.
    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func addIngredient() {
        ingredients.append(DraftIngredient())
    }

    func addStep() {
        steps.append(DraftStep())
    }

    /// Eine Mahlzeit-Eignung an-/abwählen.
    func toggleMealType(_ type: MealType) {
        if suitableMealTypes.contains(type) {
            suitableMealTypes.remove(type)
        } else {
            suitableMealTypes.insert(type)
        }
    }

    /// Beim Kategoriewechsel: Unterkategorie zurücksetzen, falls sie nicht
    /// zur neuen Kategorie gehört, und Fachdaten bei „Wurst & Räuchern“
    /// automatisch einblenden.
    func categoryChanged() {
        if let subcategory, subcategory.category !== category {
            self.subcategory = nil
        }
        if category?.isSausageSmokingCategory == true {
            includeSausageDetails = true
        }
    }
}
