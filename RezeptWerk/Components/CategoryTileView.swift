import SwiftUI

/// Kachel einer Kategorie — Icon im Holzkreis, Name, Rezeptanzahl.
struct CategoryTileView: View {
    let category: RecipeCategory

    var body: some View {
        HStack(spacing: AppSpacing.m) {
            Image(systemName: category.iconName)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(AppColors.copper)
                .frame(width: 46, height: 46)
                .background(AppColors.wood.opacity(0.16), in: Circle())

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
