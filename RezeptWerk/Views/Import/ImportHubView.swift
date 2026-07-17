import SwiftUI

/// Die Import-Zentrale: alle Wege, ein Rezept in die App zu bekommen.
struct ImportHubView: View {

    @State private var showManualEditor = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.m) {
                    Text("Egal woher dein Rezept kommt — am Ende siehst du immer eine Vorschau und kannst alles prüfen und anpassen, bevor gespeichert wird.")
                        .font(AppTypography.secondary)
                        .foregroundStyle(AppColors.textSecondary)
                        .padding(.bottom, AppSpacing.s)

                    NavigationLink {
                        PhotoImportView()
                    } label: {
                        importCard(
                            icon: "camera.viewfinder",
                            title: "Foto oder Scan",
                            subtitle: "Rezept abfotografieren oder aus der Mediathek wählen — der Text wird automatisch erkannt."
                        )
                    }

                    NavigationLink {
                        PDFImportView()
                    } label: {
                        importCard(
                            icon: "doc.text",
                            title: "PDF",
                            subtitle: "Rezept-PDF auswählen — auch gescannte PDFs werden gelesen."
                        )
                    }

                    NavigationLink {
                        WebImportView()
                    } label: {
                        importCard(
                            icon: "link",
                            title: "Webseite",
                            subtitle: "Link einfügen — Titel, Zutaten, Schritte und Bild werden übernommen."
                        )
                    }

                    NavigationLink {
                        ClipboardImportView()
                    } label: {
                        importCard(
                            icon: "doc.on.clipboard",
                            title: "Text einfügen",
                            subtitle: "Kopierten Rezepttext einfügen — die App erkennt Zutaten und Schritte."
                        )
                    }

                    Button {
                        showManualEditor = true
                    } label: {
                        importCard(
                            icon: "square.and.pencil",
                            title: "Von Hand eintippen",
                            subtitle: "Das klassische Handwerk: Rezept selbst anlegen."
                        )
                    }
                }
                .padding(AppSpacing.screen)
            }
            .screenBackground()
            .navigationTitle("Importieren")
            .sheet(isPresented: $showManualEditor) {
                RecipeEditorView(recipe: nil)
            }
        }
    }

    private func importCard(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: AppSpacing.m) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(AppColors.copper)
                .frame(width: 52, height: 52)
                .background(AppColors.wood.opacity(0.16), in: Circle())

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(title)
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(AppColors.textPrimary)

                Text(subtitle)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.textSecondary.opacity(0.6))
        }
        .card(padding: AppSpacing.l)
    }
}

#Preview {
    ImportHubView()
        .modelContainer(PreviewSupport.container)
}
