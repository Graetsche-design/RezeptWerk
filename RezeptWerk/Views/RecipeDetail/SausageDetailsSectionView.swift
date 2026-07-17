import SwiftUI

/// Der Fachdaten-Block für Wurst- und Räucherrezepte.
///
/// Zeigt nur ausgefüllte Felder — und hebt die Sicherheits- und
/// Hygienehinweise deutlich hervor.
struct SausageDetailsSectionView: View {

    let details: SausageSmokingDetails

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            SectionHeaderView(title: "Fachdaten · Wurst & Räuchern")

            VStack(alignment: .leading, spacing: 0) {
                Group {
                    if let meat = FormatHelpers.amountText(details.meatWeightKg) {
                        row("Fleischmenge", "\(meat) kg")
                    }
                    if !details.seasoningPerKg.isEmpty {
                        row("Gewürze je kg", details.seasoningPerKg)
                    }
                    if let nps = FormatHelpers.amountText(details.npsGramsPerKg) {
                        row("Nitritpökelsalz", "\(nps) g/kg")
                    }
                    if !details.cutterAids.isEmpty {
                        row("Kutterhilfsmittel", details.cutterAids)
                    }
                    if let ice = FormatHelpers.amountText(details.iceWaterPercent) {
                        row("Schüttung/Eis", "\(ice) %")
                    }
                    if !details.casing.isEmpty {
                        row("Darm/Kaliber", details.casing)
                    }
                }

                Group {
                    if details.smokingMethod != .none {
                        row("Räucherart", details.smokingMethod.label)
                    }
                    if let temp = details.smokingTemperatureCelsius {
                        row("Räuchertemperatur", "\(temp) °C")
                    }
                    if let time = details.smokingTimeMinutes {
                        row("Räucherzeit", FormatHelpers.minutesText(time))
                    }
                    if let scald = details.scaldingTemperatureCelsius {
                        row("Brühtemperatur", "\(scald) °C")
                    }
                    if let core = details.coreTemperatureCelsius {
                        row("Kerntemperatur", "\(core) °C")
                    }
                    if let curing = details.curingDays {
                        row("Reifezeit", curing == 1 ? "1 Tag" : "\(curing) Tage")
                    }
                    if let drying = details.dryingDays {
                        row("Trocknungszeit", drying == 1 ? "1 Tag" : "\(drying) Tage")
                    }
                }
            }
            .card()

            if !details.safetyNotes.isEmpty {
                safetyBox
            }
        }
    }

    /// Eine Beschriftung-Wert-Zeile.
    private func row(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(label)
                    .font(AppTypography.secondary)
                    .foregroundStyle(AppColors.textSecondary)
                Spacer(minLength: AppSpacing.m)
                Text(value)
                    .font(AppTypography.body.weight(.medium))
                    .foregroundStyle(AppColors.textPrimary)
                    .multilineTextAlignment(.trailing)
            }
            .padding(.vertical, AppSpacing.s)

            Divider()
                .overlay(AppColors.separator.opacity(0.6))
        }
    }

    /// Hervorgehobene Box für Sicherheit & Hygiene.
    private var safetyBox: some View {
        HStack(alignment: .top, spacing: AppSpacing.m) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 20))
                .foregroundStyle(AppColors.copper)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Sicherheit & Hygiene")
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(AppColors.textPrimary)
                Text(details.safetyNotes)
                    .font(AppTypography.secondary)
                    .foregroundStyle(AppColors.textPrimary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.l)
        .background(AppColors.copper.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .strokeBorder(AppColors.copper.opacity(0.35), lineWidth: 1)
        )
    }
}
