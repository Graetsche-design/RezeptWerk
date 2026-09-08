import SwiftUI

/// Kleiner Schlagwort-Chip, z. B. „Dutch Oven“.
///
/// `isSelected` hebt den Chip kupferfarben hervor (für Filter und Editor).
/// Das Antippen behandelt der Aufrufer (Button drumherum oder `onTapGesture`).
struct TagChipView: View {
    let text: String
    var isSelected: Bool = false

    var body: some View {
        Text(text)
            .font(AppTypography.caption.weight(.medium))
            .foregroundStyle(isSelected ? AppColors.backgroundPrimary : AppColors.textSecondary)
            .padding(.horizontal, AppSpacing.s + 2)
            .padding(.vertical, 5)
            .background(
                isSelected ? AnyShapeStyle(AppColors.copper) : AnyShapeStyle(AppColors.backgroundSunken),
                in: Capsule()
            )
            .overlay(
                Capsule().strokeBorder(
                    isSelected ? Color.clear : AppColors.separator,
                    lineWidth: 1
                )
            )
    }
}
