import SwiftUI

/// Das Zutaten-Blatt im Kochmodus — zum Nachschauen und Abhaken,
/// ohne den aktuellen Schritt zu verlassen.
struct CookingIngredientsSheet: View {

    let viewModel: CookingModeViewModel
    let fontScale: Double

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(viewModel.recipe.sortedIngredients) { ingredient in
                        Button {
                            viewModel.toggleIngredient(ingredient)
                        } label: {
                            HStack(spacing: AppSpacing.m) {
                                Image(systemName: viewModel.isChecked(ingredient)
                                      ? "checkmark.circle.fill"
                                      : "circle")
                                    .font(.system(size: 22))
                                    .foregroundStyle(viewModel.isChecked(ingredient)
                                                     ? AppColors.copper
                                                     : AppColors.textSecondary)

                                Text(ingredient.displayText())
                                    .font(AppTypography.cookingMeta(scale: fontScale))
                                    .foregroundStyle(AppColors.textPrimary)
                                    .strikethrough(viewModel.isChecked(ingredient))
                                    .opacity(viewModel.isChecked(ingredient) ? 0.55 : 1)
                                    .multilineTextAlignment(.leading)

                                Spacer(minLength: 0)
                            }
                            .padding(.vertical, AppSpacing.m)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        Divider()
                            .overlay(AppColors.separator.opacity(0.6))
                    }
                }
                .padding(.horizontal, AppSpacing.screen)
            }
            .background(AppColors.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("Zutaten · \(viewModel.recipe.servings) Portionen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
