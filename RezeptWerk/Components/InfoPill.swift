import SwiftUI

/// Kleine Info-Pille mit Symbol und Text, z. B. „⏱ 45 Min.“ oder „👥 4“.
struct InfoPill: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppColors.copper)
            Text(text)
                .font(AppTypography.caption.weight(.medium))
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(.horizontal, AppSpacing.s)
        .padding(.vertical, 4)
        .sunken()
    }
}
