import SwiftUI

/// Die zwei großen Schnellzugriffe auf dem Dashboard:
/// „Neues Rezept“ und „Importieren“.
struct QuickActionButtons: View {
    let onNewRecipe: () -> Void
    let onImport: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.m) {
            actionCard(
                icon: "square.and.pencil",
                title: "Neues Rezept",
                subtitle: "Selbst anlegen",
                action: onNewRecipe
            )
            actionCard(
                icon: "square.and.arrow.down",
                title: "Importieren",
                subtitle: "Foto, PDF, Web …",
                action: onImport
            )
        }
    }

    private func actionCard(
        icon: String,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AppSpacing.s) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(AppColors.copperGradient, in: Circle())

                Text(title)
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(AppColors.textPrimary)

                Text(subtitle)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .card(padding: AppSpacing.l)
        }
        .buttonStyle(.plain)
    }
}
