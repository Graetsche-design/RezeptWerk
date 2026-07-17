import Foundation

/// Liest strukturierte Rezeptdaten (schema.org/Recipe) aus dem HTML einer
/// Webseite.
///
/// Hintergrund: Fast alle großen Rezeptseiten (Chefkoch, Lecker,
/// Essen & Trinken, Kitchen Stories …) betten ihre Rezepte als
/// **JSON-LD** in die Seite ein, damit Suchmaschinen sie verstehen:
///
/// ```html
/// <script type="application/ld+json">
///   { "@type": "Recipe", "name": "…", "recipeIngredient": [...], ... }
/// </script>
/// ```
///
/// Genau diese Blöcke sucht und liest dieser Parser. Das ist deutlich
/// robuster, als das sichtbare HTML zu interpretieren.
///
/// Die Daten kommen in der Praxis in vielen Varianten (Strings, Arrays,
/// verschachtelte Objekte) — deshalb arbeitet der Parser bewusst mit
/// `JSONSerialization` und toleranten Hilfsfunktionen statt mit `Decodable`.
enum SchemaOrgRecipeParser {

    /// Sucht im HTML nach einem schema.org-Rezept.
    /// Gibt `nil` zurück, wenn keines gefunden wurde (→ Fallback im Service).
    static func parse(html: String) -> ParsedRecipe? {
        for jsonString in extractJSONLDBlocks(from: html) {
            guard let data = jsonString.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data)
            else { continue }

            if let recipeObject = findRecipeObject(in: json) {
                return buildParsedRecipe(from: recipeObject)
            }
        }
        return nil
    }

    // MARK: JSON-LD-Blöcke finden

    /// Extrahiert die Inhalte aller `<script type="application/ld+json">`-Blöcke.
    private static func extractJSONLDBlocks(from html: String) -> [String] {
        let pattern = #"<script[^>]*type\s*=\s*["']application/ld\+json["'][^>]*>([\s\S]*?)</script>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return []
        }
        let range = NSRange(html.startIndex..., in: html)
        return regex.matches(in: html, range: range).compactMap { match in
            guard let blockRange = Range(match.range(at: 1), in: html) else { return nil }
            return String(html[blockRange])
        }
    }

    /// Sucht rekursiv nach einem Objekt mit `"@type": "Recipe"` —
    /// auch in Arrays und in `@graph`-Containern.
    private static func findRecipeObject(in json: Any) -> [String: Any]? {
        if let dict = json as? [String: Any] {
            if isRecipeType(dict["@type"]) {
                return dict
            }
            // Häufig: { "@graph": [ {...}, {"@type": "Recipe", ...} ] }
            for value in dict.values {
                if let found = findRecipeObject(in: value) {
                    return found
                }
            }
        } else if let array = json as? [Any] {
            for element in array {
                if let found = findRecipeObject(in: element) {
                    return found
                }
            }
        }
        return nil
    }

    private static func isRecipeType(_ typeValue: Any?) -> Bool {
        if let type = typeValue as? String {
            return type.caseInsensitiveCompare("Recipe") == .orderedSame
        }
        if let types = typeValue as? [String] {
            return types.contains { $0.caseInsensitiveCompare("Recipe") == .orderedSame }
        }
        return false
    }

    // MARK: Felder übernehmen

    private static func buildParsedRecipe(from recipe: [String: Any]) -> ParsedRecipe {
        var result = ParsedRecipe()

        result.title = cleanHTMLText(string(recipe["name"]) ?? "")

        // Zutaten: Liste von Strings → durch den Zutaten-Zeilenparser schicken.
        let ingredientStrings = stringArray(recipe["recipeIngredient"] ?? recipe["ingredients"])
        result.ingredients = ingredientStrings.map {
            RecipeTextParser.parseIngredientLine(cleanHTMLText($0))
        }

        result.steps = instructionTexts(recipe["recipeInstructions"])

        // Portionen: "4", 4, "4 Portionen", ["4"] …
        if let yieldText = string(recipe["recipeYield"]) ?? stringArray(recipe["recipeYield"]).first,
           let match = yieldText.range(of: #"\d{1,2}"#, options: .regularExpression) {
            result.servings = Int(yieldText[match])
        }

        // Zeiten im ISO-8601-Dauerformat: "PT1H30M" = 1 Std. 30 Min.
        result.prepMinutes = isoDurationMinutes(string(recipe["prepTime"]))
        result.cookMinutes = isoDurationMinutes(string(recipe["cookTime"]))
        if result.prepMinutes == nil, result.cookMinutes == nil {
            result.cookMinutes = isoDurationMinutes(string(recipe["totalTime"]))
        }

        // Schlagworte (oft sehr viele — wir übernehmen maximal sechs kurze).
        let keywords: [String]
        if let keywordString = string(recipe["keywords"]) {
            keywords = keywordString.components(separatedBy: ",")
        } else {
            keywords = stringArray(recipe["keywords"])
        }
        result.tags = keywords
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && $0.count <= 25 }
            .prefix(6)
            .map { $0 }

        // Kurzbeschreibung als Notiz übernehmen.
        if let description = string(recipe["description"]) {
            result.notes = String(cleanHTMLText(description).prefix(300))
        }

        result.imageURLString = imageURL(recipe["image"])

        return result
    }

    /// Zubereitungsschritte aus allen üblichen Varianten einsammeln:
    /// String, [String], [HowToStep], [HowToSection mit itemListElement].
    private static func instructionTexts(_ value: Any?) -> [String] {
        guard let value else { return [] }

        if let text = value as? String {
            // Ein einzelner Textblock → an Zeilenumbrüchen aufteilen.
            return cleanHTMLText(text)
                .components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
        }

        if let array = value as? [Any] {
            return array.flatMap { element -> [String] in
                if let text = element as? String {
                    let cleaned = cleanHTMLText(text)
                    return cleaned.isEmpty ? [] : [cleaned]
                }
                if let dict = element as? [String: Any] {
                    // HowToSection: enthält weitere Schritte.
                    if let nested = dict["itemListElement"] {
                        return instructionTexts(nested)
                    }
                    // HowToStep: { "text": "..." }
                    if let text = string(dict["text"]) ?? string(dict["name"]) {
                        let cleaned = cleanHTMLText(text)
                        return cleaned.isEmpty ? [] : [cleaned]
                    }
                }
                return []
            }
        }

        return []
    }

    /// Bild-URL aus allen üblichen Varianten:
    /// String, [String], ImageObject {url: …}, [ImageObject].
    private static func imageURL(_ value: Any?) -> String? {
        if let url = value as? String { return url }
        if let array = value as? [Any] { return array.compactMap { imageURL($0) }.first }
        if let dict = value as? [String: Any] { return string(dict["url"]) }
        return nil
    }

    // MARK: Kleine Helfer

    private static func string(_ value: Any?) -> String? {
        if let text = value as? String, !text.isEmpty { return text }
        if let number = value as? NSNumber { return number.stringValue }
        return nil
    }

    private static func stringArray(_ value: Any?) -> [String] {
        if let array = value as? [String] { return array }
        if let array = value as? [Any] { return array.compactMap { $0 as? String } }
        if let single = value as? String { return [single] }
        return []
    }

    /// ISO-8601-Dauer → Minuten: "PT1H30M" → 90, "PT45M" → 45.
    private static func isoDurationMinutes(_ value: String?) -> Int? {
        guard let value else { return nil }
        var minutes = 0
        if let hourMatch = value.range(of: #"(\d+)H"#, options: .regularExpression) {
            minutes += (Int(value[hourMatch].dropLast()) ?? 0) * 60
        }
        if let minuteMatch = value.range(of: #"(\d+)M"#, options: .regularExpression) {
            minutes += Int(value[minuteMatch].dropLast()) ?? 0
        }
        return minutes > 0 ? minutes : nil
    }

    /// Entfernt HTML-Tags und dekodiert die häufigsten HTML-Entities.
    /// Bewusst einfach gehalten — reicht für Rezepttexte vollkommen aus.
    static func cleanHTMLText(_ text: String) -> String {
        var result = text

        // Zeilenumbruch-Tags in echte Umbrüche verwandeln.
        for breakTag in ["<br>", "<br/>", "<br />", "</p>", "</li>"] {
            result = result.replacingOccurrences(of: breakTag, with: "\n", options: .caseInsensitive)
        }

        // Alle übrigen Tags entfernen.
        result = result.replacingOccurrences(of: #"<[^>]+>"#, with: "", options: .regularExpression)

        // Häufige Entities ersetzen.
        let entities: [String: String] = [
            "&amp;": "&", "&lt;": "<", "&gt;": ">", "&quot;": "\"",
            "&#39;": "'", "&apos;": "'", "&nbsp;": " ",
            "&auml;": "ä", "&ouml;": "ö", "&uuml;": "ü",
            "&Auml;": "Ä", "&Ouml;": "Ö", "&Uuml;": "Ü", "&szlig;": "ß",
        ]
        for (entity, character) in entities {
            result = result.replacingOccurrences(of: entity, with: character)
        }

        // Numerische Entities (&#252; → ü).
        while let match = result.range(of: #"&#(\d+);"#, options: .regularExpression) {
            let digits = result[match].dropFirst(2).dropLast()
            if let code = UInt32(digits), let scalar = Unicode.Scalar(code) {
                result.replaceSubrange(match, with: String(Character(scalar)))
            } else {
                result.replaceSubrange(match, with: "")
            }
        }

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
