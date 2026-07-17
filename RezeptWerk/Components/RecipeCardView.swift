import SwiftUI

/// Große horizontale Rezeptkarte für die Listendarstellung (iPhone).
///
/// Zeigt Bild, Kategorie, Titel, Bewertung, Zeit, Schwierigkeit und Tags —
/// alles, was man zum schnellen Wiederfinden braucht.
struct RecipeCardView: View {
    let recipe: Recipe

    var body: some View {
        HStack(spacing: AppSpacing.m) {
            RecipeImageView(
                data: recipe.coverImageData,
                placeholderIcon: recipe.category?.iconName ?? "fork.knife"
            )
            .frame(width: 104, height: 104)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous))

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                if let categoryName = recipe.category?.name {
                    Text(categoryName)
                        .font(AppTypography.label)
                        .textCase(.uppercase)
                        .kerning(1)
                        .foregroundStyle(AppColors.copper)
                }

                Text(recipe.title)
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack(spacing: AppSpacing.s) {
                    if recipe.rating > 0 {
                        RatingStarsView(rating: recipe.rating, size: 11)
                    }
                    if recipe.totalMinutes > 0 {
                        InfoPill(icon: "clock", text: FormatHelpers.minutesText(recipe.totalMinutes))
                    }
                    DifficultyBadge(difficulty: recipe.difficulty)
                }

                if !recipe.tagNames.isEmpty {
                    // Maximal zwei Tags auf der Karte, der Rest als „+n“.
                    HStack(spacing: AppSpacing.xs) {
                        ForEach(recipe.tagNames.prefix(2), id: \.self) { tag in
                            TagChipView(text: tag)
                        }
                        if recipe.tagNames.count > 2 {
                            Text("+\(recipe.tagNames.count - 2)")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .overlay(alignment: .topTrailing) {
            if recipe.isFavorite {
                Image(systemName: "heart.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(AppColors.copper)
            }
        }
        .card(padding: AppSpacing.m)
        .contentShape(Rectangle())
    }
}
