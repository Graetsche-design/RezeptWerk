import SwiftUI

/// Verarbeitet einen über die Teilen-Erweiterung geteilten Inhalt.
///
/// Nutzt denselben Ablauf wie der normale Import: Web-Link → Web-Parser,
/// Text → Text-Parser; am Ende die vertraute Import-Vorschau. So gibt es
/// keinen Sonderweg, alles läuft über `ImportViewModel` und
/// `ImportPreviewView`.
struct SharedImportView: View {

    let pending: SharedImportInbox.Pending

    @State private var viewModel = ImportViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: AppSpacing.l) {
                if viewModel.isWorking {
                    ProgressView()
                        .controlSize(.large)
                    Text(viewModel.workingMessage)
                        .font(AppTypography.secondary)
                        .foregroundStyle(AppColors.textSecondary)
                } else if viewModel.error != nil {
                    // Der Fehler-Alert (unten) erklärt das Problem.
                    EmptyStateView(
                        icon: "tray.and.arrow.down",
                        title: "Konnte nicht übernommen werden",
                        message: "Schließe dieses Fenster – Details siehst du in der Meldung."
                    )
                } else {
                    ProgressView()
                        .controlSize(.large)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .screenBackground()
            .navigationTitle("Geteiltes Rezept")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
            }
            .navigationDestination(item: $viewModel.parsedRecipe) { parsed in
                ImportPreviewView(parsed: parsed)
            }
            .importErrorAlert($viewModel.error)
            .task {
                await runImport()
            }
        }
    }

    private func runImport() async {
        if pending.kind == "url" {
            await viewModel.importWeb(urlString: pending.content)
        } else {
            await viewModel.importClipboard(text: pending.content)
        }
    }
}
