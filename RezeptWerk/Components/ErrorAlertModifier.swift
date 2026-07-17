import SwiftUI

/// Zeigt Import-Fehler als freundlichen Alert mit Meldung und Tipp.
///
/// Verwendung:
/// ```swift
/// .importErrorAlert($viewModel.error)
/// ```
private struct ImportErrorAlertModifier: ViewModifier {
    @Binding var error: ImportError?

    func body(content: Content) -> some View {
        content
            .alert(
                "Das hat leider nicht geklappt",
                isPresented: Binding(
                    get: { error != nil },
                    set: { isPresented in
                        if !isPresented { error = nil }
                    }
                )
            ) {
                Button("Verstanden", role: .cancel) {}
            } message: {
                if let error {
                    Text([error.errorDescription, error.recoverySuggestion]
                        .compactMap(\.self)
                        .joined(separator: "\n\n"))
                }
            }
    }
}

extension View {
    /// Hängt die Standard-Fehleranzeige für Importe an die View.
    func importErrorAlert(_ error: Binding<ImportError?>) -> some View {
        modifier(ImportErrorAlertModifier(error: error))
    }
}
