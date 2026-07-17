import SwiftUI
import UIKit

/// Eine einzelne Schritt-Seite im Kochmodus — großer, ruhiger Text,
/// nichts lenkt ab. Hat der Schritt ein Foto, erscheint es unter dem Text.
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

                // Optionales Schritt-Foto — groß genug für den Blick vom Herd.
                if let data = step.imageData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 220)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
                }
            }
            .padding(AppSpacing.screen)
            .padding(.top, AppSpacing.l)
        }
    }
}
