import SwiftUI

/// Der Maß-Umrechner: amerikanische Rezept-Angaben in deutsche Maße.
///
/// Drei Modi:
/// - **Volumen**: Cups/EL/TL/ml → Gramm, zutatenabhängig (Dichte-Richtwerte
///   in `UmrechnerData`).
/// - **Gewicht**: Unzen und Pfund ↔ Gramm, beide Richtungen auf einen Blick.
/// - **Temperatur**: °F ↔ °C, dazu die Gasherd-Stufen als Orientierung.
///
/// Bewusst OHNE eigenen `NavigationStack` (lebt im Dashboard-Stack —
/// gleiches Muster wie die übrigen Werkzeuge).
struct UmrechnerView: View {

    /// Die drei Umrechnungs-Arten.
    private enum Mode: String, CaseIterable, Identifiable {
        case volume
        case weight
        case temperature

        var id: String { rawValue }

        var label: String {
            switch self {
            case .volume: "Volumen"
            case .weight: "Gewicht"
            case .temperature: "Temperatur"
            }
        }
    }

    @State private var mode: Mode = .volume

    /// Der eingegebene Wert als Text („1,5“ erlaubt).
    @State private var amountText = "1"

    @State private var selectedUnit: VolumeUnit = .cup
    @State private var selectedIngredientID = UmrechnerData.ingredients[0].id

    /// Der eingegebene Wert als Zahl (nil bei leerer/unlesbarer Eingabe).
    private var amount: Double? {
        FormatHelpers.parseAmount(amountText)
    }

    private var selectedIngredient: ConversionIngredient {
        UmrechnerData.ingredients.first { $0.id == selectedIngredientID }
            ?? UmrechnerData.ingredients[0]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                Picker("Umrechnung", selection: $mode) {
                    ForEach(Mode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                inputSection

                switch mode {
                case .volume: volumeResultSection
                case .weight: weightResultSection
                case .temperature: temperatureResultSection
                }

                infoBox
            }
            .padding(.horizontal, AppSpacing.screen)
            .padding(.top, AppSpacing.l)
            .padding(.bottom, AppSpacing.xxl)
        }
        .screenBackground()
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Umrechner")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Eingabe

    /// Eingabefeld + (im Volumen-Modus) Einheit und Zutat.
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            SectionHeaderView(title: "Eingabe")

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: AppSpacing.s) {
                    Text(mode == .temperature ? "Wert" : "Menge")
                        .font(AppTypography.secondary)
                        .foregroundStyle(AppColors.textSecondary)

                    Spacer(minLength: AppSpacing.m)

                    TextField("–", text: $amountText)
                        .keyboardType(mode == .temperature ? .numbersAndPunctuation : .decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 90)
                        .font(AppTypography.body.weight(.semibold))

                    if mode == .volume {
                        Picker("Einheit", selection: $selectedUnit) {
                            ForEach(VolumeUnit.allCases) { unit in
                                Text(unit.label).tag(unit)
                            }
                        }
                        .labelsHidden()
                    }
                }
                .padding(.vertical, AppSpacing.s)

                if mode == .volume {
                    Divider()
                        .overlay(AppColors.separator.opacity(0.6))

                    HStack {
                        Text("Zutat")
                            .font(AppTypography.secondary)
                            .foregroundStyle(AppColors.textSecondary)

                        Spacer(minLength: AppSpacing.m)

                        Picker("Zutat", selection: $selectedIngredientID) {
                            ForEach(UmrechnerData.ingredients) { ingredient in
                                Text(ingredient.name).tag(ingredient.id)
                            }
                        }
                        .labelsHidden()
                    }
                    .padding(.vertical, AppSpacing.xs)
                }
            }
            .card()
        }
    }

    // MARK: Ergebnisse

    private var volumeResultSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            SectionHeaderView(title: "Ergebnis")

            VStack(alignment: .leading, spacing: 0) {
                let grams = amount.map {
                    UmrechnerData.grams(amount: $0, unit: selectedUnit, ingredient: selectedIngredient)
                }
                resultRow(
                    "\(amountText.isEmpty ? "–" : amountText) \(selectedUnit.label) \(selectedIngredient.name)",
                    grams.flatMap { FormatHelpers.amountText($0.rounded()) }.map { "\($0) g" } ?? "–"
                )
                resultRow(
                    "Das entspricht",
                    amount.flatMap { FormatHelpers.amountText(($0 * selectedUnit.milliliters).rounded()) }
                        .map { "\($0) ml" } ?? "–"
                )
            }
            .card()
        }
    }

    private var weightResultSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            SectionHeaderView(title: "Ergebnis")

            VStack(alignment: .leading, spacing: 0) {
                resultRow(
                    "\(displayAmount) Unzen (oz)",
                    amount.flatMap { FormatHelpers.amountText(UmrechnerData.grams(fromOunces: $0).rounded()) }
                        .map { "\($0) g" } ?? "–"
                )
                resultRow(
                    "\(displayAmount) Pfund (lb)",
                    amount.flatMap { FormatHelpers.amountText(UmrechnerData.grams(fromPounds: $0).rounded()) }
                        .map { "\($0) g" } ?? "–"
                )
                resultRow(
                    "\(displayAmount) g in Unzen",
                    amount.flatMap { FormatHelpers.amountText($0 / 28.3495) }.map { "\($0) oz" } ?? "–"
                )
            }
            .card()
        }
    }

    private var temperatureResultSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            SectionHeaderView(title: "Ergebnis")

            VStack(alignment: .leading, spacing: 0) {
                resultRow(
                    "\(displayAmount) °F in Celsius",
                    amount.map { "\(Int(UmrechnerData.celsius(fromFahrenheit: $0).rounded())) °C" } ?? "–"
                )
                resultRow(
                    "\(displayAmount) °C in Fahrenheit",
                    amount.map { "\(Int(UmrechnerData.fahrenheit(fromCelsius: $0).rounded())) °F" } ?? "–"
                )
            }
            .card()

            SectionHeaderView(title: "Gasherd-Stufen")

            VStack(alignment: .leading, spacing: 0) {
                ForEach(UmrechnerData.gasMarks, id: \.stufe) { mark in
                    resultRow(mark.stufe, mark.celsius)
                }
            }
            .card()
        }
    }

    /// Die Eingabe für die Ergebnis-Beschriftungen („–“ wenn leer).
    private var displayAmount: String {
        let trimmed = amountText.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "–" : trimmed
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

    /// Hinweis-Box (Muster: `KerntemperaturView.safetyBox`).
    private var infoBox: some View {
        HStack(alignment: .top, spacing: AppSpacing.m) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(AppColors.copper)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Gut zu wissen")
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(AppColors.textPrimary)
                Text("Cup-Angaben sind Schüttmaße — je nach Zutat und Befüllung sind das Richtwerte. Beim Backen im Zweifel lieber wiegen.")
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
        UmrechnerView()
    }
}
