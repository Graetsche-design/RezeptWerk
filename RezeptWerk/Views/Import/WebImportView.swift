import SwiftUI

/// Web-Import: Rezept-Link einfügen → Seite laden → Rezeptdaten erkennen.
struct WebImportView: View {

    @State private var viewModel = ImportViewModel()
    @State private var urlText = ""
    @FocusState private var urlFieldFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.l) {
                VStack(alignment: .leading, spacing: AppSpacing.m) {
                    Text("Rezept-Adresse")
                        .font(AppTypography.label)
                        .textCase(.uppercase)
                        .kerning(1)
                        .foregroundStyle(AppColors.textSecondary)

                    HStack(spacing: AppSpacing.s) {
                        TextField("z. B. chefkoch.de/rezepte/…", text: $urlText)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($urlFieldFocused)
                            .padding(AppSpacing.m)
                            .sunken()

                        // System-Button: fügt den Link aus der Zwischenablage
                        // ein (fragt den Nutzer nicht ungefragt aus).
                        PasteButton(payloadType: String.self) { strings in
                            if let first = strings.first {
                                urlText = first.trimmingCharacters(in: .whitespacesAndNewlines)
                            }
                        }
                        .labelStyle(.iconOnly)
                        .buttonBorderShape(.capsule)
                        .tint(AppColors.copper)
                    }

                    Button {
                        urlFieldFocused = false
                        Task {
                            await viewModel.importWeb(urlString: urlText)
                        }
                    } label: {
                        Label("Rezept laden", systemImage: "arrow.down.circle")
                    }
                    .buttonStyle(.rwPrimary)
                    .disabled(urlText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .card()

                HStack(alignment: .top, spacing: AppSpacing.m) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 18))
                        .foregroundStyle(AppColors.copper)

                    Text("Funktioniert mit den meisten Rezeptseiten (Chefkoch, Lecker, Kitchen Stories u. v. m.) — sie betten ihre Rezepte in einem Standardformat ein, das RezeptWerk lesen kann. Falls eine Seite nicht klappt: Rezepttext kopieren und über „Text einfügen“ importieren.")
                        .font(AppTypography.secondary)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .card()
            }
            .padding(AppSpacing.screen)
        }
        .screenBackground()
        .navigationTitle("Webseite importieren")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if viewModel.isWorking {
                VStack(spacing: AppSpacing.m) {
                    ProgressView()
                        .controlSize(.large)
                    Text(viewModel.workingMessage)
                        .font(AppTypography.secondary)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .padding(AppSpacing.xxl)
                .background(AppColors.backgroundElevated, in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
                .shadow(color: AppColors.cardShadow, radius: 16, y: 6)
            }
        }
        .navigationDestination(item: $viewModel.parsedRecipe) { parsed in
            ImportPreviewView(parsed: parsed)
        }
        .importErrorAlert($viewModel.error)
    }
}
