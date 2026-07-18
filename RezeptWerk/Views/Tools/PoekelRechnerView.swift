import SwiftUI

/// Der Pökel-Rechner fürs **Nasspökeln** (Lakepökeln) — das Gegenstück
/// zum Wurst-Rechner, der die Trockenpökel-Mengen (g je kg) abdeckt.
///
/// Eingaben: Fleischgewicht, Wassermenge, Lakenstärke in Prozent
/// (mit Schnellwahl), optional Zucker je Liter und die dickste Stelle
/// des Fleischs für die Zeitschätzung. Alle Eingaben werden gemerkt
/// (`@AppStorage`), damit die eigene Standard-Lake beim nächsten Öffnen
/// wieder da ist.
///
/// Bewusst OHNE eigenen `NavigationStack` (lebt im Dashboard-Stack).
struct PoekelRechnerView: View {

    // Gemerkte Eingaben (Texte, deutsche Kommas erlaubt).
    @AppStorage(SettingsKeys.brineMeatKg) private var meatKgText = ""
    @AppStorage(SettingsKeys.brineWaterLiters) private var waterLitersText = ""
    @AppStorage(SettingsKeys.brineStrengthPercent) private var strengthText = "8"
    @AppStorage(SettingsKeys.brineSugarPerLiter) private var sugarPerLiterText = ""
    @AppStorage(SettingsKeys.brineThicknessCm) private var thicknessText = ""

    // MARK: Richtwerte (fachlich prüfbar — bewusst an EINER Stelle)

    /// Übliche Hobby-Konvention: Eine „8-%-Lake“ bedeutet 80 g NPS je
    /// Liter Wasser — also Lakenstärke × 10 g/L.
    static let gramsPerLiterPerPercent: Double = 10

    /// Faustformel Pökelzeit: 1 Tag je Zentimeter Fleischdicke …
    static let daysPerCentimeter: Double = 1
    /// … plus Sicherheitstage, damit das Salz sicher bis zum Kern zieht.
    static let safetyDays = 2

    /// Schnellwahl der Lakenstärke: übliche Stufen.
    private static let strengthPresets: [(label: String, percent: String)] = [
        ("mild", "6"),
        ("klassisch", "8"),
        ("kräftig", "10"),
        ("schnell", "12"),
    ]

    // MARK: Rechnen (statisch und damit testbar)

    /// NPS-Menge in Gramm für die Lake.
    static func npsGrams(waterLiters: Double, strengthPercent: Double) -> Double {
        waterLiters * strengthPercent * gramsPerLiterPerPercent
    }

    /// Zucker-Menge in Gramm (g je Liter × Liter).
    static func sugarGrams(waterLiters: Double, gramsPerLiter: Double) -> Double {
        waterLiters * gramsPerLiter
    }

    /// Pökelzeit in Tagen nach der dicksten Stelle des Fleischs.
    static func curingDays(thicknessCm: Double) -> Int {
        Int((thicknessCm * daysPerCentimeter).rounded(.up)) + safetyDays
    }

    /// Durchbrennen (Salzausgleich) danach: etwa die halbe Pökelzeit.
    static func burnThroughDays(curingDays: Int) -> Int {
        max(1, Int((Double(curingDays) / 2).rounded(.up)))
    }

    /// Wasser-Faustregel: rund 40 % des Fleischgewichts.
    static func suggestedWaterLiters(meatKg: Double) -> Double {
        meatKg * 0.4
    }

    // MARK: Abgeleitete Werte

    private var meatKg: Double? { FormatHelpers.parseAmount(meatKgText) }
    private var waterLiters: Double? { FormatHelpers.parseAmount(waterLitersText) }
    private var strengthPercent: Double? { FormatHelpers.parseAmount(strengthText) }
    private var sugarPerLiter: Double? { FormatHelpers.parseAmount(sugarPerLiterText) }
    private var thicknessCm: Double? { FormatHelpers.parseAmount(thicknessText) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                inputSection
                strengthSection
                resultSection
                safetyBox
            }
            .padding(.horizontal, AppSpacing.screen)
            .padding(.top, AppSpacing.l)
            .padding(.bottom, AppSpacing.xxl)
        }
        .screenBackground()
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Pökel-Rechner")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Eingaben

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            SectionHeaderView(title: "Fleisch & Lake")

            VStack(alignment: .leading, spacing: 0) {
                inputRow("Fleischgewicht", text: $meatKgText, unit: "kg")
                inputRow("Wassermenge", text: $waterLitersText, unit: "l")

                // Faustregel-Vorschlag: füllt das Wasserfeld auf Wunsch.
                if let meatKg, meatKg > 0 {
                    let suggested = Self.suggestedWaterLiters(meatKg: meatKg)
                    Button {
                        waterLitersText = FormatHelpers.amountText(suggested) ?? ""
                    } label: {
                        Text("Vorschlag übernehmen: \(FormatHelpers.amountText(suggested) ?? "–") l (ca. 40 % — das Fleisch muss bedeckt sein)")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.copper)
                            .multilineTextAlignment(.leading)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, AppSpacing.s)
                }

                inputRow("Zucker (optional)", text: $sugarPerLiterText, unit: "g/l")
                    .padding(.top, AppSpacing.xs)
                inputRow("Dickste Stelle", text: $thicknessText, unit: "cm")
            }
            .card()
        }
    }

    /// Lakenstärke: freies Feld + Schnellwahl-Chips.
    private var strengthSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            SectionHeaderView(title: "Lakenstärke")

            VStack(alignment: .leading, spacing: 0) {
                inputRow("Lakenstärke", text: $strengthText, unit: "%")

                FlowLayout(spacing: AppSpacing.s) {
                    ForEach(Self.strengthPresets, id: \.percent) { preset in
                        let isSelected = strengthText == preset.percent
                        Button {
                            strengthText = preset.percent
                        } label: {
                            Text("\(preset.percent) % \(preset.label)")
                                .font(AppTypography.caption.weight(.medium))
                                .foregroundStyle(isSelected ? .white : AppColors.textSecondary)
                                .padding(.horizontal, AppSpacing.m)
                                .padding(.vertical, AppSpacing.s)
                                .background(
                                    isSelected
                                        ? AnyShapeStyle(AppColors.copper)
                                        : AnyShapeStyle(AppColors.backgroundSunken),
                                    in: Capsule()
                                )
                                .overlay(
                                    Capsule().strokeBorder(
                                        isSelected ? Color.clear : AppColors.separator,
                                        lineWidth: 1
                                    )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, AppSpacing.m)
            }
            .card()
        }
    }

    // MARK: Ergebnis

    private var resultSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            SectionHeaderView(title: "Ergebnis")

            VStack(alignment: .leading, spacing: 0) {
                let nps: Double? = {
                    guard let waterLiters, waterLiters > 0,
                          let strengthPercent, strengthPercent > 0 else { return nil }
                    return Self.npsGrams(waterLiters: waterLiters, strengthPercent: strengthPercent)
                }()

                resultRow(
                    "Nitritpökelsalz (NPS)",
                    nps.flatMap { FormatHelpers.amountText($0.rounded()) }.map { "\($0) g" } ?? "–"
                )
                if let strengthPercent, strengthPercent > 0 {
                    resultRow(
                        "Das sind je Liter Wasser",
                        FormatHelpers.amountText(strengthPercent * Self.gramsPerLiterPerPercent)
                            .map { "\($0) g" } ?? "–"
                    )
                }

                if let waterLiters, waterLiters > 0,
                   let sugarPerLiter, sugarPerLiter > 0 {
                    resultRow(
                        "Zucker",
                        FormatHelpers.amountText(
                            Self.sugarGrams(waterLiters: waterLiters, gramsPerLiter: sugarPerLiter).rounded()
                        ).map { "\($0) g" } ?? "–"
                    )
                }

                if let thicknessCm, thicknessCm > 0 {
                    let days = Self.curingDays(thicknessCm: thicknessCm)
                    resultRow("Pökelzeit", days == 1 ? "ca. 1 Tag" : "ca. \(days) Tage")
                    let burnThrough = Self.burnThroughDays(curingDays: days)
                    resultRow(
                        "Durchbrennen danach",
                        burnThrough == 1 ? "ca. 1 Tag" : "ca. \(burnThrough) Tage"
                    )
                }
            }
            .card()
        }
    }

    // MARK: Bausteine

    /// Beschriftung + Eingabefeld + Einheit.
    private func inputRow(_ label: String, text: Binding<String>, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: AppSpacing.s) {
                Text(label)
                    .font(AppTypography.secondary)
                    .foregroundStyle(AppColors.textSecondary)

                Spacer(minLength: AppSpacing.m)

                TextField("–", text: text)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 70)
                    .font(AppTypography.body.weight(.semibold))

                Text(unit)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(width: 32, alignment: .leading)
            }
            .padding(.vertical, AppSpacing.s)

            Divider()
                .overlay(AppColors.separator.opacity(0.6))
        }
    }

    /// Beschriftung-Wert-Zeile (Muster: `WurstRechnerView.resultRow`).
    private func resultRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(label)
                    .font(AppTypography.secondary)
                    .foregroundStyle(AppColors.textSecondary)
                Spacer(minLength: AppSpacing.m)
                Text(value)
                    .font(AppTypography.body.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)
            }
            .padding(.vertical, AppSpacing.s)

            Divider()
                .overlay(AppColors.separator.opacity(0.6))
        }
    }

    /// Sicherheits-Hinweis (Muster: `WurstRechnerView.safetyBox`).
    private var safetyBox: some View {
        HStack(alignment: .top, spacing: AppSpacing.m) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 20))
                .foregroundStyle(AppColors.copper)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Sicherheit")
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(AppColors.textPrimary)
                Text("Alle Werte sind übliche Richtwerte fürs Nasspökeln — maßgeblich ist deine eigene, erprobte Rezeptur. NPS grammgenau abwiegen, das Fleisch vollständig bedecken und durchgehend kühl lagern (4–7 °C).")
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

#Preview {
    NavigationStack {
        PoekelRechnerView()
    }
}
