import SwiftUI

/// Auffälliges Hinweisfenster für Meldungen des Entwicklers an alle Nutzer
/// (siehe `AnnouncementService`) — z. B. der Hinweis, vor einem Update ein
/// Backup zu erstellen.
///
/// Der Hintergrund wird abgedunkelt, die Meldung steht als Karte in der
/// Bildschirmmitte und muss mit „Verstanden“ bestätigt werden. Danach
/// erscheint sie erst wieder, wenn es eine neue Meldung gibt.
struct AnnouncementOverlayView: View {
    let announcement: Announcement
    let onDismiss: () -> Void

    /// Steuert die kleine Aufplopp-Animation der Karte beim Erscheinen.
    @State private var appeared = false

    var body: some View {
        ZStack {
            // Abgedunkelter Hintergrund — lenkt den Blick auf die Karte.
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            // Die Hinweis-Karte.
            VStack(spacing: AppSpacing.l) {
                ZStack {
                    Circle()
                        .fill(AppColors.copper.opacity(0.15))
                        .frame(width: 76, height: 76)

                    Image(systemName: "megaphone.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(AppColors.copper)
                }

                if let titel = announcement.titel, !titel.isEmpty {
                    Text(titel)
                        .font(AppTypography.recipeTitle)
                        .foregroundStyle(AppColors.textPrimary)
                        .multilineTextAlignment(.center)
                }

                Text(announcement.nachricht)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Button("Verstanden", action: onDismiss)
                    .buttonStyle(.rwPrimary)
                    .padding(.top, AppSpacing.s)
            }
            .padding(AppSpacing.xl)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .fill(AppColors.backgroundElevated)
                    .shadow(color: .black.opacity(0.3), radius: 24, y: 8)
            )
            .frame(maxWidth: 420)
            .padding(.horizontal, AppSpacing.xxl)
            .scaleEffect(appeared ? 1 : 0.85)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                appeared = true
            }
        }
    }
}

#Preview {
    AnnouncementOverlayView(
        announcement: Announcement(
            titel: "Update-Hinweis",
            nachricht: "Demnächst erscheint Version 1.1. Bitte erstelle "
                + "vorher unter Einstellungen → Backup ein Backup."
        ),
        onDismiss: {}
    )
}
