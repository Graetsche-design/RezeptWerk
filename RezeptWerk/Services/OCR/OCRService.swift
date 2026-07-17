import Foundation
import Vision
import UIKit

/// Texterkennung (OCR) mit Apples Vision-Framework.
///
/// Erkennt deutschen und englischen Text in Fotos — z. B. von einer
/// abfotografierten Rezeptkarte oder einer Kochbuchseite.
struct OCRService {

    /// Erkennt Text in Bilddaten (JPEG/PNG aus Fotoauswahl oder Scanner).
    func recognizeText(in imageData: Data) async throws -> String {
        guard let uiImage = UIImage(data: imageData), let cgImage = uiImage.cgImage else {
            throw ImportError.imageUnreadable
        }
        return try await recognizeText(in: cgImage)
    }

    /// Erkennt Text in einem `CGImage`.
    ///
    /// Die eigentliche Vision-Arbeit ist rechenintensiv und läuft deshalb
    /// in einem `Task.detached` abseits des Main Threads.
    func recognizeText(in cgImage: CGImage) async throws -> String {
        let task = Task.detached(priority: .userInitiated) { () throws -> String in
            let request = VNRecognizeTextRequest()
            // `.accurate` ist langsamer, aber deutlich besser für Fließtext.
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["de-DE", "en-US"]
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try handler.perform([request])

            let observations = request.results ?? []
            // Vision liefert die Textblöcke bereits in Lesereihenfolge.
            // (Bei mehrspaltigen Layouts kann die Reihenfolge leiden —
            // dafür gibt es die manuelle Korrektur in der Import-Vorschau.)
            let lines = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            return lines.joined(separator: "\n")
        }
        return try await task.value
    }
}
