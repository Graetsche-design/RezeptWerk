import SwiftUI
import VisionKit
import UIKit

/// Brücke zu Apples Dokumentenscanner (`VNDocumentCameraViewController`).
///
/// Der Scanner erkennt Papierkanten automatisch, richtet die Seiten gerade
/// und liefert pro Seite ein sauberes Bild — ideal für Rezeptkarten und
/// Kochbuchseiten. Es gibt ihn nur als UIKit-Controller, daher diese
/// kleine `UIViewControllerRepresentable`-Hülle.
struct DocumentScannerView: UIViewControllerRepresentable {

    /// Liefert die gescannten Seiten als JPEG-Daten (bereits komprimiert).
    let onScanned: ([Data]) -> Void

    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scanner = VNDocumentCameraViewController()
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {
        // Nichts zu aktualisieren — der Scanner verwaltet sich selbst.
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: DocumentScannerView

        init(parent: DocumentScannerView) {
            self.parent = parent
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            var pages: [Data] = []
            for pageIndex in 0..<scan.pageCount {
                let image = scan.imageOfPage(at: pageIndex)
                if let jpegData = image.jpegData(compressionQuality: 0.85) {
                    pages.append(jpegData)
                }
            }
            parent.dismiss()
            if !pages.isEmpty {
                parent.onScanned(pages)
            }
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.dismiss()
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: Error
        ) {
            parent.dismiss()
        }
    }
}
