import SwiftUI

/// Horizontale Rezept-Reihe mit Überschrift — für „Favoriten“ und
/// „Zuletzt hinzugefügt“ auf dem Dashboard.
///
/// Die Karten sind `NavigationLink`s mit dem Rezept als Wert; das Ziel
/// registriert der umgebende `NavigationStack` über
/// `navigationDestination(for: Recipe.self)`.
struct RecipeCarouselSection: View {
    let title: String
    let recipes: [Recipe]
    var seeAllTitle: String? = nil
    var seeAllAction: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            SectionHeaderView(title: title, actionTitle: seeAllTitle, action: seeAllAction)
                .padding(.horizontal, AppSpacing.screen)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: AppSpacing.m) {
                    ForEach(recipes) { recipe in
                        NavigationLink(value: recipe) {
                            RecipeGridCardView(recipe: recipe)
                                .frame(width: 230)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AppSpacing.screen)
                // Platz für den Kartenschatten, damit er nicht abgeschnitten wird.
                .padding(.vertical, AppSpacing.s)
            }
        }
    }
}
