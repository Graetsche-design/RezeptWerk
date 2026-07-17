import SwiftUI

/// Eingabefelder für die Wurst- & Räucher-Fachdaten im Editor.
///
/// Wird nur angezeigt, wenn „Fachdaten erfassen“ aktiv ist —
/// normale Rezepte bleiben davon unberührt.
struct SausageDetailsEditorSection: View {

    @Bindable var draft: RecipeDraft

    var body: some View {
        Group {
            numberRow("Fleischmenge", text: $draft.meatWeightText, suffix: "kg")

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Gewürze je kg")
                TextField(
                    "z. B. 3 g Pfeffer · 2 g Majoran · 1 g Knoblauch",
                    text: $draft.seasoningPerKg,
                    axis: .vertical
                )
                .lineLimit(2...4)
                .font(AppTypography.secondary)
            }

            numberRow("Nitritpökelsalz (NPS)", text: $draft.npsText, suffix: "g/kg")
            textRow("Kutterhilfsmittel", text: $draft.cutterAids, prompt: "z. B. 3 g/kg Phosphat")
            numberRow("Schüttung/Eis", text: $draft.iceWaterText, suffix: "%")
            textRow("Darm/Kaliber", text: $draft.casing, prompt: "z. B. Schweinedarm 28/30")

            Picker("Räucherart", selection: $draft.smokingMethod) {
                ForEach(SmokingMethod.allCases) { method in
                    Text(method.label).tag(method)
                }
            }

            if draft.smokingMethod != .none {
                numberRow(
                    "Räuchertemperatur",
                    text: $draft.smokingTempText,
                    suffix: "°C",
                    hint: "üblich: \(draft.smokingMethod.temperatureHint)"
                )
                numberRow("Räucherzeit", text: $draft.smokingTimeText, suffix: "Min.")
            }

            numberRow("Brühtemperatur", text: $draft.scaldingTempText, suffix: "°C")
            numberRow("Kerntemperatur", text: $draft.coreTempText, suffix: "°C")
            numberRow("Reifezeit", text: $draft.curingDaysText, suffix: "Tage")
            numberRow("Trocknungszeit", text: $draft.dryingDaysText, suffix: "Tage")

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Label("Sicherheit & Hygiene", systemImage: "checkmark.shield")
                    .foregroundStyle(AppColors.copper)
                    .font(AppTypography.secondary.weight(.medium))
                TextField(
                    "z. B. NPS exakt abwiegen, Kühlkette einhalten, Kerntemperatur sicher erreichen …",
                    text: $draft.safetyNotes,
                    axis: .vertical
                )
                .lineLimit(2...5)
                .font(AppTypography.secondary)
            }
        }
    }

    // MARK: Zeilen-Helfer

    private func numberRow(
        _ label: String,
        text: Binding<String>,
        suffix: String,
        hint: String? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(label)
                Spacer()
                TextField("–", text: text)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 70)
                Text(suffix)
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(minWidth: 36, alignment: .leading)
            }
            if let hint {
                Text(hint)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }

    private func textRow(_ label: String, text: Binding<String>, prompt: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
            TextField(prompt, text: text)
                .font(AppTypography.secondary)
        }
    }
}
