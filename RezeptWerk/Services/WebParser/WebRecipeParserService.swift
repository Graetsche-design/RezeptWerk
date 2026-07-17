import Foundation

/// Importiert ein Rezept von einer Webseite.
///
/// Ablauf:
/// 1. Seite laden (mit Browser-Kennung, da manche Seiten Apps aussperren).
/// 2. **Bevorzugt**: strukturierte schema.org-Rezeptdaten lesen
///    (`SchemaOrgRecipeParser`) — das liefert saubere Titel, Zutaten,
///    Schritte, Zeiten und das Rezeptbild.
/// 3. **Fallback**: sichtbaren Seitentext extrahieren und durch den
///    allgemeinen `RecipeTextParser` schicken. Das Ergebnis ist gröber,
///    kann aber in der Import-Vorschau korrigiert werden.
///
/// Grenzen der MVP-Version (bewusst, siehe README): Seiten, die ihre
/// Inhalte erst per JavaScript nachladen UND keine schema.org-Daten
/// einbetten, können nicht gelesen werden. Dafür gibt es den
/// Zwischenablage-Import als zuverlässigen Umweg.
struct WebRecipeParserService {

    /// Browser-Kennung, damit Rezeptseiten die Anfrage normal beantworten.
    private let userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1"

    /// Lädt die Seite und versucht, ein Rezept zu erkennen.
    func fetchRecipe(from urlString: String) async throws -> ParsedRecipe {
        guard let url = normalizedURL(from: urlString) else {
            throw ImportError.invalidURL
        }

        let html = try await loadHTML(from: url)

        var parsed: ParsedRecipe

        if let structured = SchemaOrgRecipeParser.parse(html: html) {
            // Bester Fall: strukturierte Daten gefunden.
            parsed = structured
        } else {
            // Fallback: Seitentext extrahieren und heuristisch parsen.
            let visibleText = extractVisibleText(from: html)
            guard visibleText.count > 50 else {
                throw ImportError.noRecipeDataFound
            }
            parsed = RecipeTextParser.parse(visibleText)

            // Der Seitentitel ist meist besser als die erste Textzeile.
            if let pageTitle = extractPageTitle(from: html) {
                parsed.title = pageTitle
            }
            // Vorschaubild der Seite (og:image) als Rezeptbild versuchen.
            if parsed.imageURLString == nil {
                parsed.imageURLString = extractOpenGraphImage(from: html)
            }
        }

        // Quelle eintragen.
        parsed.sourceURLString = url.absoluteString
        parsed.sourceText = url.host() ?? url.absoluteString

        // Rezeptbild herunterladen (Fehler hier sind nicht schlimm —
        // dann gibt es eben kein Bild).
        if parsed.imageData == nil,
           let imageURLString = parsed.imageURLString,
           let imageURL = URL(string: imageURLString) {
            parsed.imageData = try? await loadImageData(from: imageURL)
        }

        guard !parsed.isEmpty else {
            throw ImportError.noRecipeDataFound
        }
        return parsed
    }

    // MARK: Laden

    /// Ergänzt fehlendes „https://“ und prüft die Adresse.
    private func normalizedURL(from input: String) -> URL? {
        var text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        if !text.lowercased().hasPrefix("http://") && !text.lowercased().hasPrefix("https://") {
            text = "https://" + text
        }
        guard let url = URL(string: text), url.host() != nil else { return nil }
        return url
    }

    private func loadHTML(from url: URL) async throws -> String {
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 20

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw ImportError.webPageUnreachable
        }

        if let httpResponse = response as? HTTPURLResponse,
           !(200..<400).contains(httpResponse.statusCode) {
            throw ImportError.webPageUnreachable
        }

        // Erst UTF-8 versuchen, dann Latin-1 (ältere Seiten).
        guard let html = String(data: data, encoding: .utf8)
                ?? String(data: data, encoding: .isoLatin1) else {
            throw ImportError.noRecipeDataFound
        }
        return html
    }

    private func loadImageData(from url: URL) async throws -> Data? {
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15
        let (data, _) = try await URLSession.shared.data(for: request)
        // Auf Speichergröße komprimieren wie bei der Fotoauswahl.
        return ImageCompressor.compressForStorage(data)
    }

    // MARK: HTML-Auswertung (Fallback-Weg)

    /// Holt den sichtbaren Text aus dem HTML (Skripte/Styles entfernt).
    private func extractVisibleText(from html: String) -> String {
        var working = html

        // Script- und Style-Blöcke komplett entfernen.
        for blockTag in ["script", "style", "noscript", "header", "footer", "nav"] {
            working = working.replacingOccurrences(
                of: "<\(blockTag)[\\s\\S]*?</\(blockTag)>",
                with: " ",
                options: [.regularExpression, .caseInsensitive]
            )
        }

        let text = SchemaOrgRecipeParser.cleanHTMLText(working)

        // Mehrfache Leerzeilen/Leerzeichen zusammenfassen.
        return text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }

    /// Liest den `<title>` der Seite und entfernt Seitennamen-Anhängsel
    /// („Saftiger Gulasch | Chefkoch“ → „Saftiger Gulasch“).
    private func extractPageTitle(from html: String) -> String? {
        guard let match = html.range(
            of: #"<title[^>]*>([\s\S]*?)</title>"#,
            options: [.regularExpression, .caseInsensitive]
        ) else { return nil }

        var title = SchemaOrgRecipeParser.cleanHTMLText(String(html[match]))
        for separator in [" | ", " – ", " - ", " — "] {
            if let range = title.range(of: separator) {
                title = String(title[..<range.lowerBound])
            }
        }
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// Liest das Vorschaubild der Seite (`og:image`).
    private func extractOpenGraphImage(from html: String) -> String? {
        let pattern = #"<meta[^>]*property\s*=\s*["']og:image["'][^>]*content\s*=\s*["']([^"']+)["']"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
              let urlRange = Range(match.range(at: 1), in: html)
        else { return nil }
        return String(html[urlRange])
    }
}
