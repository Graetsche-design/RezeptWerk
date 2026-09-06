import SwiftUI

/// Freundlicher Leerzustand, wenn es (noch) nichts anzuzeigen gibt.
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: AppSpacing.l) {
            Image(systemName: icon)
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(AppColors.copper.opacity(0.7))

            VStack(spacing: AppSpacing.s) {
                Text(title)
                    .font(AppTypography.sectionTitle)
                    .foregroundStyle(AppColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(AppTypography.secondary)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.rwPrimary)
                    .frame(maxWidth: 280)
            }
        }
        .padding(AppSpacing.xxl)
        .frame(maxWidth: .infinity)
    }
}
