import SwiftUI

/// Zwischenablage-Import: kopierten Rezepttext einfügen →
/// Titel, Zutaten und Schritte werden automatisch erkannt.
struct ClipboardImportView: View {

    @State private var viewModel = ImportViewModel()
    @State private var text = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.l) {
                VStack(alignment: .leading, spacing: AppSpacing.m) {
                    HStack {
                        Text("Rezepttext")
                            .font(AppTypography.label)
                            .textCase(.uppercase)
                            .kerning(1)
                            .foregroundStyle(AppColors.textSecondary)

                        Spacer()

                        // System-Button: holt den Text aus der Zwischenablage —
                        // nur auf Tipp des Nutzers, kein ungefragtes Mitlesen.
                        PasteButton(payloadType: String.self) { strings in
                            if let first = strings.first {
                                text = first
                            }
                        }
                        .labelStyle(.titleAndIcon)
                        .buttonBorderShape(.capsule)
                        .tint(AppColors.copper)
                        .controlSize(.small)
                    }

                    TextEditor(text: $text)
                        .frame(minHeight: 220)
                        .font(.callout)
                        .scrollContentBackground(.hidden)
                        .padding(AppSpacing.s)
                        .sunken()

                    Button {
                        Task {
                            await viewModel.importClipboard(text: text)
                        }
                    } label: {
                        Label("Text erkennen", systemImage: "wand.and.stars")
                    }
                    .buttonStyle(.rwPrimary)
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).count < 10)
                }
                .card()

                HStack(alignment: .top, spacing: AppSpacing.m) {
                    Image(systemName: "lightbulb")
                        .font(.system(size: 18))
                        .foregroundStyle(AppColors.copper)

                    Text("Tipp: Überschriften wie „Zutaten“ und „Zubereitung“ im Text helfen der Erkennung. Aber auch ohne sie versucht RezeptWerk, Mengen und Schritte zu unterscheiden.")
                        .font(AppTypography.secondary)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .card()
            }
            .padding(AppSpacing.screen)
        }
        .screenBackground()
        .navigationTitle("Text einfügen")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .navigationDestination(item: $viewModel.parsedRecipe) { parsed in
            ImportPreviewView(parsed: parsed)
        }
        .importErrorAlert($viewModel.error)
    }
}
