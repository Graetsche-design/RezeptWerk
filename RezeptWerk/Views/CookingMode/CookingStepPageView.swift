import SwiftUI

/// Eine einzelne Schritt-Seite im Kochmodus — großer, ruhiger Text,
/// nichts lenkt ab.
struct CookingStepPageView: View {

    let stepNumber: Int
    let step: RecipeStep
    let fontScale: Double

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.l) {
                Text("Schritt \(stepNumber)")
                    .font(AppTypography.label)
                    .textCase(.uppercase)
                    .kerning(1.5)
                    .foregroundStyle(AppColors.copper)

                Text(step.text)
                    .font(AppTypography.cookingStep(scale: fontScale))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineSpacing(6 * fontScale)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(AppSpacing.screen)
            .padding(.top, AppSpacing.l)
        }
    }
}
