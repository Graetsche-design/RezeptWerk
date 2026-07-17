import SwiftUI

/// Zeigt einen freundlichen Hinweis, wenn das Speichern in der Datenbank
/// fehlgeschlagen ist — sehr selten (z. B. voller Gerätespeicher), aber
/// dann soll es der Nutzer wissen, statt still Daten zu verlieren.
///
/// Verwendung:
/// ```swift
/// @State private var saveFailed = false
/// …
/// do { try modelContext.save() } catch { saveFailed = true }
/// …
/// .saveErrorAlert($saveFailed)
/// ```
private struct SaveErrorAlertModifier: ViewModifier {
    @Binding var isPresented: Bool

    func body(content: Content) -> some View {
        content
            .alert("Speichern hat nicht geklappt", isPresented: $isPresented) {
                Button("Verstanden", role: .cancel) {}
            } message: {
                Text("Die Änderung konnte nicht gespeichert werden. Prüfe den freien Speicherplatz und versuch es danach noch einmal.")
            }
    }
}

extension View {
    /// Hängt die Standard-Fehleranzeige für Speicherfehler an die View.
    func saveErrorAlert(_ isPresented: Binding<Bool>) -> some View {
        modifier(SaveErrorAlertModifier(isPresented: isPresented))
    }
}
