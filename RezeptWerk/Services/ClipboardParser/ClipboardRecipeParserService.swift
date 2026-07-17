import Foundation

/// Erkennt ein Rezept in eingefügtem Text (Zwischenablage).
///
/// Die eigentliche Erkennung übernimmt der zentrale `RecipeTextParser` —
/// dieser Service prüft nur die Eingabe und ergänzt die Quellenangabe.
///
/// Hinweis zur Bedienung: Die `ClipboardImportView` nutzt SwiftUIs
/// `PasteButton` und ein Textfeld. So entscheidet immer der Nutzer selbst,
/// wann die App auf die Zwischenablage zugreift (kein ungefragtes Mitlesen).
struct ClipboardRecipeParserService {

    /// Parst eingefügten Text. Wirft `clipboardEmpty`, wenn zu wenig
    /// Text vorhanden ist, um sinnvoll etwas zu erkennen.
    func parse(text: String) throws -> ParsedRecipe {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 10 else {
            throw ImportError.clipboardEmpty
        }

        var parsed = RecipeTextParser.parse(trimmed)
        if parsed.sourceText.isEmpty {
            parsed.sourceText = "Aus Zwischenablage eingefügt"
        }
        return parsed
    }
}
