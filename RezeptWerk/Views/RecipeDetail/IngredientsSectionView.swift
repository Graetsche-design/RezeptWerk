import SwiftUI

/// Zutatenliste mit Portionsrechner.
///
/// Über den Stepper lassen sich die Portionen anpassen — alle Mengen
/// werden live umgerechnet (gespeichert wird dabei nichts, das Rezept
/// behält seine Original-Portionszahl).
struct IngredientsSectionView: View {

    let recipe: Recipe
    @Binding var displayedServings: Int

    /// Umrechnungsfaktor: angezeigte Portionen ÷ Original-Portionen.
    private var factor: Double {
        guard recipe.servings > 0, displayedServings > 0 else { return 1 }
        return Double(displayedServings) / Double(recipe.servings)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            SectionHeaderView(title: "Zutaten")

            VStack(alignment: .leading, spacing: 0) {
                // Portionsrechner.
                Stepper(value: $displayedServings, in: 1...50) {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "person.2")
                            .font(.system(size: 14))
                            .foregroundStyle(AppColors.copper)
                        Text("\(displayedServings) Portionen")
                            .font(AppTypography.body.weight(.medium))
                            .foregroundStyle(AppColors.textPrimary)
                    }
                }
                .padding(.bottom, AppSpacing.m)

                if displayedServings != recipe.servings {
                    Text("Mengen umgerechnet (Original: \(recipe.servings) Portionen)")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.copper)
                        .padding(.bottom, AppSpacing.m)
                }

                Divider()
                    .overlay(AppColors.separator)

                // Die Zutaten.
                ForEach(recipe.sortedIngredients) { ingredient in
                    HStack(alignment: .firstTextBaseline, spacing: AppSpacing.m) {
                        Text(amountText(for: ingredient))
                            .font(AppTypography.body.weight(.semibold).monospacedDigit())
                            .foregroundStyle(AppColors.copper)
                            .frame(width: 86, alignment: .trailing)

                        Text(ingredient.name)
                            .font(AppTypography.body)
                            .foregroundStyle(AppColors.textPrimary)

                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, AppSpacing.s)

                    if ingredient.persistentModelID != recipe.sortedIngredients.last?.persistentModelID {
                        Divider()
                            .overlay(AppColors.separator.opacity(0.6))
                    }
                }
            }
            .card()
        }
    }

    /// „250 g“, „1,5 kg“ — oder „–“ für Zutaten ohne Menge.
    private func amountText(for ingredient: Ingredient) -> String {
        var parts: [String] = []
        if let amount = FormatHelpers.amountText(ingredient.amount.map { $0 * factor }) {
            parts.append(amount)
        }
        if !ingredient.unit.isEmpty {
            parts.append(ingredient.unit)
        }
        return parts.isEmpty ? "–" : parts.joined(separator: " ")
    }
}
