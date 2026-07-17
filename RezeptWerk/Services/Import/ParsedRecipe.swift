import Foundation

/// Eine beim Parsen erkannte Zutat (noch kein Datenbankobjekt).
struct ParsedIngredient: Sendable, Hashable {
    var amount: Double?
    var unit: String = ""
    var name: String = ""
}

/// Das gemeinsame Übergabeformat aller Import-Wege.
///
/// Egal ob OCR, PDF, Web oder Zwischenablage — jeder Service liefert am
/// Ende ein `ParsedRecipe`. Die Import-Vorschau zeigt es an, und beim
/// „Bearbeiten“ wird daraus ein `RecipeDraft` für den Rezepteditor.
///
/// Bewusst ein einfaches `Sendable`-Struct (kein SwiftData-Modell), damit
/// die Services es auch im Hintergrund erzeugen dürfen. `Hashable`, damit
/// die Import-Views es direkt als Navigationsziel verwenden können.
struct ParsedRecipe: Sendable, Hashable {
    var title: String = ""
    var ingredients: [ParsedIngredient] = []
    var steps: [String] = []
    var servings: Int?
    var prepMinutes: Int?
    var cookMinutes: Int?
    var tags: [String] = []
    var notes: String = ""

    /// Quelle als Anzeigetext, z. B. „chefkoch.de“ oder „PDF: oma.pdf“.
    var sourceText: String = ""
    /// Quelle als Link (bei Web-Importen).
    var sourceURLString: String = ""

    /// Bereits heruntergeladenes Rezeptbild (Web-Import).
    var imageData: Data?
    /// Bild-URL als Zwischenschritt — der Web-Service lädt sie herunter
    /// und füllt damit `imageData`.
    var imageURLString: String?

    /// Der komplette erkannte Originaltext — wird in der Import-Vorschau
    /// zum Nachschlagen angezeigt, falls die automatische Zuordnung
    /// danebenliegt.
    var rawText: String = ""

    /// `true`, wenn praktisch nichts erkannt wurde.
    var isEmpty: Bool {
        title.isEmpty && ingredients.isEmpty && steps.isEmpty
    }
}
