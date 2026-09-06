import SwiftUI

/// Die zwei großen Schnellzugriffe auf dem Dashboard:
/// „Neues Rezept“ als glühende Kupfer-Kachel, „Importieren“ als dunkle
/// Kachel mit Kupfer-Kontur.
struct QuickActionButtons: View {
    let onNewRecipe: () -> Void
    let onImport: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.m) {
            Button(action: onNewRecipe) {
                tile(
                    icon: "square.and.pencil",
                    title: "Neues Rezept",
                    subtitle: "Selbst anlegen",
                    isPrimary: true
                )
            }
            .buttonStyle(.plain)

            Button(action: onImport) {
                tile(
                    icon: "square.and.arrow.down",
                    title: "Importieren",
                    subtitle: "Foto, PDF, Web …",
                    isPrimary: false
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func tile(icon: String, title: String, subtitle: String, isPrimary: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if isPrimary {
                Image(systemName: icon)
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(.white.opacity(0.22), in: Circle())
            } else {
                IconBadge(systemName: icon, size: 40)
            }

            Spacer(minLength: AppSpacing.m)

            Text(title)
                .font(AppTypography.cardTitle)
                .foregroundStyle(isPrimary ? Color.white : AppColors.textPrimary)

            Text(subtitle)
                .font(AppTypography.caption)
                .foregroundStyle(isPrimary ? Color.white.opacity(0.85) : AppColors.textSecondary)
                .padding(.top, 3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 108)
        .padding(AppSpacing.l)
        .background(
            isPrimary
                ? AnyShapeStyle(AppColors.copperGradient)
                : AnyShapeStyle(AppColors.backgroundElevated)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .strokeBorder(
                    isPrimary ? Color.clear : AppColors.copper.opacity(0.4),
                    lineWidth: 1
                )
        )
        .shadow(
            color: isPrimary ? AppColors.glowShadow : AppColors.cardShadow,
            radius: 14, x: 0, y: 8
        )
    }
}
