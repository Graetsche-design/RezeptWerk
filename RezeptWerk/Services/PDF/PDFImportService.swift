import Foundation
import PDFKit
import UIKit

/// Liest Text aus PDF-Dateien.
///
/// Zwei Wege:
/// 1. **Text-PDF**: PDFKit liefert den enthaltenen Text direkt.
/// 2. **Scan-PDF** (Foto-Seiten ohne Textebene): Die Seiten werden als
///    Bilder gerendert und durch die OCR geschickt.
struct PDFImportService {

    private let ocrService = OCRService()

    /// Maximale Seitenzahl für den OCR-Fallback — schützt vor sehr großen
    /// Dokumenten (ein Rezept-PDF hat selten mehr als ein paar Seiten).
    private let maxOCRPages = 10

    /// Extrahiert den Text eines PDFs (URL aus dem Datei-Dialog).
    func extractText(from url: URL) async throws -> String {
        // Dateien aus dem System-Dialog (`fileImporter`) liegen außerhalb
        // der App-Sandbox — ohne diesen Aufruf schlägt das Öffnen fehl.
        let hasAccess = url.startAccessingSecurityScopedResource()
        defer {
            if hasAccess { url.stopAccessingSecurityScopedResource() }
        }

        guard let document = PDFDocument(url: url), !document.isLocked else {
            throw ImportError.pdfUnreadable
        }

        // Weg 1: eingebetteten Text auslesen.
        let embeddedText = (0..<document.pageCount)
            .compactMap { document.page(at: $0)?.string }
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Genug Text gefunden? Dann sind wir fertig.
        // (Unter 40 Zeichen ist es vermutlich ein gescanntes PDF.)
        if embeddedText.count >= 40 {
            return embeddedText
        }

        // Weg 2: Seiten rendern und per OCR lesen.
        var ocrText = ""
        for pageIndex in 0..<min(document.pageCount, maxOCRPages) {
            guard let page = document.page(at: pageIndex) else { continue }

            // Seite in guter Auflösung rendern (2,5-fach für scharfe OCR).
            let bounds = page.bounds(for: .mediaBox)
            let scale: CGFloat = 2.5
            let size = CGSize(width: bounds.width * scale, height: bounds.height * scale)
            let pageImage = page.thumbnail(of: size, for: .mediaBox)

            guard let cgImage = pageImage.cgImage else { continue }
            let pageText = try await ocrService.recognizeText(in: cgImage)
            if !pageText.isEmpty {
                ocrText += pageText + "\n"
            }
        }

        let result = ocrText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !result.isEmpty else {
            throw ImportError.noTextFound
        }
        return result
    }
}
