import Foundation
import Observation

/// Steuert die Import-Abläufe: ruft den passenden Service auf, zeigt den
/// Arbeitsstatus an und hält das Ergebnis (oder den Fehler) für die View.
@MainActor
@Observable
final class ImportViewModel {

    /// Läuft gerade ein Import?
    var isWorking = false
    /// Status-Text während der Arbeit („Text wird erkannt …“).
    var workingMessage = ""
    /// Das fertige Ergebnis → die View navigiert zur Import-Vorschau.
    var parsedRecipe: ParsedRecipe?
    /// Aufgetretener Fehler → die View zeigt einen freundlichen Alert.
    var error: ImportError?

    private let ocrService = OCRService()
    private let pdfService = PDFImportService()
    private let webService = WebRecipeParserService()
    private let clipboardService = ClipboardRecipeParserService()

    // MARK: Die vier Import-Wege

    /// Foto → Texterkennung → Parser.
    func importPhoto(imageData: Data) async {
        await run(message: "Text wird erkannt …", fallbackError: .noTextFound) {
            let text = try await self.ocrService.recognizeText(in: imageData)
            guard text.trimmingCharacters(in: .whitespacesAndNewlines).count >= 10 else {
                throw ImportError.noTextFound
            }
            var parsed = RecipeTextParser.parse(text)
            parsed.sourceText = "Foto-Import (Texterkennung)"
            return parsed
        }
    }

    /// Mehrere gescannte Seiten (Dokumentenscanner) → OCR je Seite → Parser.
    func importScannedPages(imageDatas: [Data]) async {
        await run(message: "Text wird erkannt …", fallbackError: .noTextFound) {
            var combinedText = ""
            for imageData in imageDatas {
                let pageText = try await self.ocrService.recognizeText(in: imageData)
                if !pageText.isEmpty {
                    combinedText += pageText + "\n"
                }
            }
            guard combinedText.trimmingCharacters(in: .whitespacesAndNewlines).count >= 10 else {
                throw ImportError.noTextFound
            }
            var parsed = RecipeTextParser.parse(combinedText)
            parsed.sourceText = "Gescanntes Rezept (Texterkennung)"
            return parsed
        }
    }

    /// PDF → Text (oder OCR) → Parser.
    func importPDF(url: URL) async {
        await run(message: "PDF wird gelesen …", fallbackError: .pdfUnreadable) {
            let text = try await self.pdfService.extractText(from: url)
            var parsed = RecipeTextParser.parse(text)
            parsed.sourceText = "PDF: \(url.lastPathComponent)"
            return parsed
        }
    }

    /// Web-Adresse → schema.org-Daten oder Text-Fallback.
    func importWeb(urlString: String) async {
        await run(message: "Webseite wird geladen …", fallbackError: .webPageUnreachable) {
            try await self.webService.fetchRecipe(from: urlString)
        }
    }

    /// Eingefügter Text → Parser.
    func importClipboard(text: String) async {
        await run(message: "Text wird erkannt …", fallbackError: .clipboardEmpty) {
            try self.clipboardService.parse(text: text)
        }
    }

    /// Zurücksetzen, wenn ein neuer Import beginnt oder die View verschwindet.
    func reset() {
        isWorking = false
        parsedRecipe = nil
        error = nil
    }

    // MARK: Gemeinsamer Ablauf

    private func run(
        message: String,
        fallbackError: ImportError,
        _ work: () async throws -> ParsedRecipe
    ) async {
        error = nil
        parsedRecipe = nil
        isWorking = true
        workingMessage = message
        defer { isWorking = false }

        do {
            parsedRecipe = try await work()
        } catch let importError as ImportError {
            error = importError
        } catch {
            // Unerwartete Fehler auf eine verständliche Meldung abbilden.
            self.error = fallbackError
        }
    }
}
