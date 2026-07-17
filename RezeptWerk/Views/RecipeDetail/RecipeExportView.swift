import SwiftUI

/// Das Teilen- & Export-Sheet eines Rezepts.
///
/// Zeigt eine Live-Vorschau des erzeugten PDFs und bietet darunter zwei
/// Wege zum Teilen — als PDF-Datei oder als Klartext. Das eigentliche
/// Teilen übernimmt das System (`ShareLink`), sodass alle installierten
/// Apps (Mail, Nachrichten, WhatsApp, „In Dateien sichern“ …) zur
/// Verfügung stehen.
struct RecipeExportView: View {

    let recipe: Recipe

    @Environment(\.dismiss) private var dismiss

    @State private var pdfData: Data?
    @State private var pdfURL: URL?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                preview

                shareBar
            }
            .background(AppColors.backgroundSunken)
            .navigationTitle("Teilen & Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
            .task {
                // PDF einmalig beim Öffnen erzeugen.
                let data = await RecipeExportService.pdfData(for: recipe)
                pdfData = data
                pdfURL = RecipeExportService.writePDF(data, title: recipe.title)
            }
        }
    }

    // MARK: Vorschau

    @ViewBuilder
    private var preview: some View {
        if let pdfData {
            PDFKitView(data: pdfData)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(spacing: AppSpacing.m) {
                ProgressView()
                    .controlSize(.large)
                Text("Vorschau wird erstellt …")
                    .font(AppTypography.secondary)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: Teilen-Leiste

    private var shareBar: some View {
        VStack(spacing: AppSpacing.m) {
            if let pdfURL {
                ShareLink(
                    item: pdfURL,
                    preview: SharePreview(recipe.title, image: Image(systemName: "doc.richtext"))
                ) {
                    Label("Als PDF teilen", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.rwPrimary)
            }

            ShareLink(item: RecipeExportService.plainText(for: recipe)) {
                Label("Als Text teilen", systemImage: "text.alignleft")
            }
            .buttonStyle(.rwSecondary)
        }
        .padding(AppSpacing.screen)
        .background(AppColors.backgroundElevated)
        .overlay(alignment: .top) {
            Divider().overlay(AppColors.separator)
        }
    }
}

#Preview {
    RecipeExportView(recipe: PreviewSupport.sausageRecipe)
        .modelContainer(PreviewSupport.container)
}
