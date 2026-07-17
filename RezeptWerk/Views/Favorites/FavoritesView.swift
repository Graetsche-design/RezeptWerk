import SwiftUI
import SwiftData

/// Alle Favoriten auf einen Blick.
struct FavoritesView: View {

    @Query(sort: \Recipe.createdAt, order: .reverse)
    private var allRecipes: [Recipe]

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var favorites: [Recipe] {
        allRecipes.filter(\.isFavorite)
    }

    var body: some View {
        NavigationStack {
            Group {
                if favorites.isEmpty {
                    EmptyStateView(
                        icon: "heart",
                        title: "Noch keine Favoriten",
                        message: "Tippe bei einem Rezept auf das Herz — dann findest du es hier sofort wieder."
                    )
                } else {
                    ScrollView {
                        if horizontalSizeClass == .compact {
                            LazyVStack(spacing: AppSpacing.m) {
                                ForEach(favorites) { recipe in
                                    NavigationLink(value: recipe) {
                                        RecipeCardView(recipe: recipe)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, AppSpacing.screen)
                            .padding(.vertical, AppSpacing.l)
                        } else {
                            LazyVGrid(
                                columns: [GridItem(.adaptive(minimum: 260), spacing: AppSpacing.l)],
                                spacing: AppSpacing.l
                            ) {
                                ForEach(favorites) { recipe in
                                    NavigationLink(value: recipe) {
                                        RecipeGridCardView(recipe: recipe)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(AppSpacing.screen)
                        }
                    }
                }
            }
            .screenBackground()
            .navigationTitle("Favoriten")
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(recipe: recipe)
            }
        }
    }
}

#Preview {
    FavoritesView()
        .modelContainer(PreviewSupport.container)
}
