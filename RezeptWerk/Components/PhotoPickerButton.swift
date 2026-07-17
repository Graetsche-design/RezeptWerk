import SwiftUI
import PhotosUI

/// Button, der die Fotoauswahl öffnet und die gewählten Bilder als
/// komprimierte JPEG-Daten zurückgibt (siehe `ImageCompressor`).
///
/// Hinweis: `PhotosPicker` benötigt KEINE Foto-Berechtigung — das System
/// zeigt die Auswahl an und die App erhält nur die gewählten Bilder.
struct PhotoPickerButton<Label: View>: View {
    /// Maximale Anzahl gleichzeitig wählbarer Bilder.
    var maxSelection: Int = 1

    /// Callback mit den fertig komprimierten Bilddaten.
    let onPicked: ([Data]) -> Void

    @ViewBuilder let label: () -> Label

    @State private var selection: [PhotosPickerItem] = []

    var body: some View {
        PhotosPicker(
            selection: $selection,
            maxSelectionCount: maxSelection,
            matching: .images
        ) {
            label()
        }
        .onChange(of: selection) { _, newItems in
            guard !newItems.isEmpty else { return }
            Task {
                var results: [Data] = []
                for item in newItems {
                    if let raw = try? await item.loadTransferable(type: Data.self),
                       let compressed = ImageCompressor.compressForStorage(raw) {
                        results.append(compressed)
                    }
                }
                selection = []
                if !results.isEmpty {
                    onPicked(results)
                }
            }
        }
    }
}
