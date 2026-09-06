import SwiftUI

/// Kachel einer Kategorie — Symbol im Kreis in der Farbe der Kategorie,
/// Name, Rezeptanzahl.
struct CategoryTileView: View {
    let category: RecipeCategory

    var body: some View {
        HStack(spacing: AppSpacing.m) {
            IconBadge(
                systemName: category.iconName,
                size: 46,
                tint: AppColors.categoryTint(iconName: category.iconName)
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(category.name)
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(category.recipeList.count == 1 ? "1 Rezept" : "\(category.recipeList.count) Rezepte")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .card(padding: AppSpacing.m)
        .contentShape(Rectangle())
    }
}
