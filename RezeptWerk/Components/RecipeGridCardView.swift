import SwiftUI

/// Kompakte vertikale Rezeptkarte — für das iPad-Grid und die
/// horizontalen Karussells auf dem Dashboard.
struct RecipeGridCardView: View {
    let recipe: Recipe

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RecipeImageView(
                data: recipe.coverImageData,
                placeholderIcon: recipe.category?.iconName ?? "fork.knife"
            )
            .frame(height: 130)
            .frame(maxWidth: .infinity)
            .clipped()
            .overlay(alignment: .topTrailing) {
                if recipe.isFavorite {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(.black.opacity(0.35), in: Circle())
                        .padding(AppSpacing.s)
                }
            }

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                if let categoryName = recipe.category?.name {
                    Text(categoryName)
                        .font(AppTypography.label)
                        .textCase(.uppercase)
                        .kerning(1)
                        .foregroundStyle(AppColors.copper)
                        .lineLimit(1)
                }

                Text(recipe.title)
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(2, reservesSpace: true)
                    .multilineTextAlignment(.leading)

                HStack(spacing: AppSpacing.s) {
                    if recipe.totalMinutes > 0 {
                        Label(FormatHelpers.minutesText(recipe.totalMinutes), systemImage: "clock")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    Spacer()
                    if recipe.rating > 0 {
                        RatingStarsView(rating: recipe.rating, size: 10)
                    }
                }
            }
            .padding(AppSpacing.m)
        }
        .cardNoPadding()
        .contentShape(Rectangle())
    }
}
