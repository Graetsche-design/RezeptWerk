import SwiftUI

/// Die Zubereitungsschritte als nummerierte Liste im Kochbuch-Stil.
struct StepsSectionView: View {

    let recipe: Recipe

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            SectionHeaderView(title: "Zubereitung")

            VStack(alignment: .leading, spacing: AppSpacing.l) {
                ForEach(Array(recipe.sortedSteps.enumerated()), id: \.element.persistentModelID) { index, step in
                    HStack(alignment: .top, spacing: AppSpacing.m) {
                        // Nummern-Kreis in Kupfer.
                        Text("\(index + 1)")
                            .font(AppTypography.cardTitle)
                            .foregroundStyle(AppColors.copper)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle().strokeBorder(AppColors.copper.opacity(0.5), lineWidth: 1.5)
                            )

                        VStack(alignment: .leading, spacing: AppSpacing.s) {
                            Text(step.text)
                                .font(AppTypography.body)
                                .foregroundStyle(AppColors.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            if let seconds = step.timerSeconds, seconds > 0 {
                                InfoPill(
                                    icon: "timer",
                                    text: "Timer: \(FormatHelpers.timerText(seconds: seconds))"
                                )
                            }
                        }
                    }
                }
            }
            .card()
        }
    }
}
