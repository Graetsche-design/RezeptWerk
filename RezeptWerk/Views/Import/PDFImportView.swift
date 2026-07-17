import SwiftUI
import UniformTypeIdentifiers

/// PDF-Import: Datei wählen → Text auslesen (notfalls per OCR) → Vorschau.
struct PDFImportView: View {

    @State private var viewModel = ImportViewModel()
    @State private var showFilePicker = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.l) {
                HStack(alignment: .top, spacing: AppSpacing.m) {
                    Image(systemName: "lightbulb")
                        .font(.system(size: 18))
                        .foregroundStyle(AppColors.copper)

                    Text("Funktioniert mit normalen Text-PDFs und mit gescannten PDFs (dann liest die Texterkennung die Seiten). Passwortgeschützte PDFs werden nicht unterstützt.")
                        .font(AppTypography.secondary)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .card()

                Button {
                    showFilePicker = true
                } label: {
                    Label("PDF auswählen", systemImage: "doc.text")
                }
                .buttonStyle(.rwPrimary)
            }
            .padding(AppSpacing.screen)
        }
        .screenBackground()
        .navigationTitle("PDF importieren")
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
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.pdf]
        ) { result in
            switch result {
            case .success(let url):
                Task {
                    await viewModel.importPDF(url: url)
                }
            case .failure:
                viewModel.error = .pdfUnreadable
            }
        }
        .navigationDestination(item: $viewModel.parsedRecipe) { parsed in
            ImportPreviewView(parsed: parsed)
        }
        .importErrorAlert($viewModel.error)
    }
}
