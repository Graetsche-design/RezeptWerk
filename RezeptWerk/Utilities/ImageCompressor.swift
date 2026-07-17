import UIKit

/// Verkleinert Bilder vor dem Speichern.
///
/// Moderne Handyfotos haben 24–48 Megapixel — für ein Rezeptbild reichen
/// 1600 px völlig. Ohne diese Komprimierung würde die Datenbank schnell
/// hunderte Megabyte groß und die Listen würden ruckeln.
enum ImageCompressor {

    /// Maximale Kantenlänge gespeicherter Rezeptbilder.
    private static let maxDimension: CGFloat = 1600

    /// Verkleinert die Bilddaten auf max. 1600 px und kodiert sie als JPEG.
    /// Gibt `nil` zurück, wenn die Daten kein lesbares Bild sind.
    static func compressForStorage(_ data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }

        let largestSide = max(image.size.width, image.size.height)

        // Bereits klein genug: nur als JPEG neu kodieren.
        guard largestSide > maxDimension else {
            return image.jpegData(compressionQuality: 0.8)
        }

        let scale = maxDimension / largestSide
        let newSize = CGSize(
            width: image.size.width * scale,
            height: image.size.height * scale
        )

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        return resized.jpegData(compressionQuality: 0.8)
    }
}
