import SwiftUI
import PDFKit

/// Zeigt PDF-Daten als blätterbare Vorschau an.
///
/// Kleine SwiftUI-Hülle um `PDFView` (PDFKit) — dient im Export-Sheet als
/// Live-Vorschau des erzeugten Rezept-PDFs.
struct PDFKitView: UIViewRepresentable {
    let data: Data

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.backgroundColor = .clear
        pdfView.document = PDFDocument(data: data)
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        // Das Dokument wird einmalig in `makeUIView` gesetzt und ändert sich
        // während der Anzeige nicht — daher hier bewusst nichts zu tun.
    }
}
