import SwiftUI

/// Herz-Button zum Markieren eines Favoriten.
struct FavoriteButton: View {
    let isFavorite: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(
                isFavorite ? "Favorit entfernen" : "Als Favorit markieren",
                systemImage: isFavorite ? "heart.fill" : "heart"
            )
            .labelStyle(.iconOnly)
            .font(.system(size: 20))
            .foregroundStyle(isFavorite ? AppColors.copper : AppColors.textSecondary)
            .symbolEffect(.bounce, value: isFavorite)
        }
        .accessibilityLabel(isFavorite ? "Favorit entfernen" : "Als Favorit markieren")
    }
}
