import SwiftUI

/// Bearbeitbare Schrittliste im Editor — jeder Schritt mit mehrzeiligem
/// Textfeld und optionalem Timer (in Minuten, Komma erlaubt: „1,5“ = 90 s).
struct StepsEditorList: View {

    @Bindable var draft: RecipeDraft

    var body: some View {
        ForEach(Array($draft.steps.enumerated()), id: \.element.id) { index, $step in
            VStack(alignment: .leading, spacing: AppSpacing.s) {
                HStack(alignment: .top, spacing: AppSpacing.m) {
                    Text("\(index + 1)")
                        .font(AppTypography.cardTitle)
                        .foregroundStyle(AppColors.copper)
                        .frame(width: 24, alignment: .center)
                        .padding(.top, 6)

                    TextField(
                        "Was ist zu tun?",
                        text: $step.text,
                        axis: .vertical
                    )
                    .lineLimit(2...6)
                }

                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "timer")
                        .font(.system(size: 13))
                        .foregroundStyle(AppColors.textSecondary)
                    TextField("Timer (Min.)", text: $step.timerMinutesText)
                        .keyboardType(.decimalPad)
                        .frame(width: 90)
                    Spacer()
                }
                .padding(.leading, 24 + AppSpacing.m)
                .font(AppTypography.secondary)
            }
            .padding(.vertical, AppSpacing.xs)
        }
        .onDelete { offsets in
            draft.steps.remove(atOffsets: offsets)
            if draft.steps.isEmpty {
                draft.addStep()
            }
        }
        .onMove { source, destination in
            draft.steps.move(fromOffsets: source, toOffset: destination)
        }

        Button {
            draft.addStep()
        } label: {
            Label("Schritt hinzufügen", systemImage: "plus.circle.fill")
                .foregroundStyle(AppColors.copper)
        }
    }
}
