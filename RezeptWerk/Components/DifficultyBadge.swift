import SwiftUI

/// Kleines Badge für den Schwierigkeitsgrad: „• Einfach“, „•• Mittel“ …
struct DifficultyBadge: View {
    let difficulty: Difficulty

    var body: some View {
        HStack(spacing: 3) {
            Text(difficulty.dots)
                .foregroundStyle(AppColors.copper)
            Text(difficulty.label)
                .foregroundStyle(AppColors.textSecondary)
        }
        .font(AppTypography.caption.weight(.medium))
        .padding(.horizontal, AppSpacing.s)
        .padding(.vertical, 4)
        .sunken()
    }
}
