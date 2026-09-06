import SwiftUI

/// Das Zutaten-Blatt im Kochmodus — zum Nachschauen und Abhaken,
/// ohne den aktuellen Schritt zu verlassen.
///
/// Die Mengen sind auf die Portionen umgerechnet, für die gekocht wird
/// (`CookingModeViewModel.servings`) — nicht zwingend die des Rezepts.
struct CookingIngredientsSheet: View {

    let viewModel: CookingModeViewModel
    let fontScale: Double

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if viewModel.isScaled {
                        Text("Mengen umgerechnet (Original: \(viewModel.recipe.servings) Portionen)")
                            .font(AppTypography.cookingMeta(scale: fontScale * 0.85))
                            .foregroundStyle(AppColors.copper)
                            .padding(.vertical, AppSpacing.m)
                    }

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

                                Text(ingredient.displayText(scaledBy: viewModel.scaleFactor))
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
            .navigationTitle("Zutaten · \(viewModel.servings) Portionen")
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
