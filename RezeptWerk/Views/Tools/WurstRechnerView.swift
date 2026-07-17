import SwiftUI
import SwiftData

/// Eine Fleisch-Zeile des Wurst-Rechners: Sorte + Gewicht in kg.
/// Wurst ist oft ein Mix (z. B. Schweineschulter + Rückenspeck) — darum
/// eine Liste statt eines einzelnen Gewichts.
struct MeatRow: Identifiable, Codable, Equatable {
    var id = UUID()
    var name = ""
    var kilogramsText = ""
}

/// Eine Zutaten-Zeile des Wurst-Rechners: „so viel Gramm je Kilogramm
/// Fleisch“. Die Menge bleibt bewusst Text (deutsche Eingabe „2,5“),
/// gerechnet wird live über `FormatHelpers.parseAmount`.
struct CalculatorRow: Identifiable, Codable, Equatable {
    var id = UUID()
    var name = ""
    var gramsPerKgText = ""
}

/// Eine Voreinstellung mit üblichen Richtwerten.
struct SausageTemplate: Identifiable {
    let id = UUID()
    let name: String
    /// Kurzer Hinweis, der nach dem Laden der Vorlage angezeigt wird.
    let note: String
    let rows: [CalculatorRow]
}

/// Der Wurst-Rechner: Fleisch-Mix eingeben (mehrere Sorten mit Gewicht),
/// Zutaten je kg pflegen — die Gesamtmengen werden live hochgerechnet.
/// Das Ergebnis lässt sich als richtiges Rezept speichern (inklusive
/// Fachdaten, Kategorie „Wurst & Räuchern“).
///
/// Fleisch- und Zutatenliste werden gemerkt (`@AppStorage`), damit die
/// eigene Standard-Rezeptur beim nächsten Öffnen wieder da ist.
/// Bewusst OHNE eigenen `NavigationStack` (lebt im Dashboard-Stack).
struct WurstRechnerView: View {

    @Environment(\.modelContext) private var modelContext

    /// Die Fleischsorten mit Gewicht (kg).
    @State private var meats: [MeatRow] = []

    /// Die aktuellen Zutaten-Zeilen (g je kg Fleisch).
    @State private var rows: [CalculatorRow] = []

    /// Hinweis der zuletzt geladenen Vorlage.
    @State private var templateNote: String?

    /// Steuert das „Als Rezept speichern“-Blatt.
    @State private var showSaveSheet = false

    /// Bestätigungstext nach dem Speichern (steuert den Hinweis-Dialog).
    @State private var saveConfirmation: String?

    /// Gemerkte Listen als JSON (überstehen App-Neustarts).
    @AppStorage(SettingsKeys.sausageCalculatorRows)
    private var savedRowsJSON = ""
    @AppStorage(SettingsKeys.sausageCalculatorMeats)
    private var savedMeatsJSON = ""

    /// Die mitgelieferten Voreinstellungen — übliche Richtwerte,
    /// jederzeit in der Liste anpassbar.
    private static let templates: [SausageTemplate] = [
        SausageTemplate(
            name: "Brühwurst",
            note: "Richtwerte für Brühwurst. Dazu kommen je nach Rezept 20–30 % Eisschüttung.",
            rows: [
                CalculatorRow(name: "Nitritpökelsalz (NPS)", gramsPerKgText: "18"),
                CalculatorRow(name: "Pfeffer, gemahlen", gramsPerKgText: "2,5"),
                CalculatorRow(name: "Kutterhilfsmittel", gramsPerKgText: "3"),
            ]
        ),
        SausageTemplate(
            name: "Rohwurst (Salami)",
            note: "Richtwerte für schnittfeste Rohwurst. Starterkulturen nach Packungsangabe dosieren.",
            rows: [
                CalculatorRow(name: "Nitritpökelsalz (NPS)", gramsPerKgText: "26"),
                CalculatorRow(name: "Pfeffer, gemahlen", gramsPerKgText: "3"),
                CalculatorRow(name: "Dextrose", gramsPerKgText: "3"),
            ]
        ),
        SausageTemplate(
            name: "Rohschinken (trocken)",
            note: "Richtwerte fürs Trockenpökeln von Rohschinken.",
            rows: [
                CalculatorRow(name: "Nitritpökelsalz (NPS)", gramsPerKgText: "38"),
                CalculatorRow(name: "Zucker", gramsPerKgText: "2"),
                CalculatorRow(name: "Pfeffer, gemahlen", gramsPerKgText: "2"),
            ]
        ),
    ]

    /// Gesamtes Fleischgewicht in kg (Summe aller Sorten).
    private var meatKg: Double {
        meats.reduce(0) { $0 + (FormatHelpers.parseAmount($1.kilogramsText) ?? 0) }
    }

    /// Summe aller berechneten Zutaten in Gramm.
    private var totalIngredientGrams: Double {
        rows.reduce(0) { $0 + grams(for: $1) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                meatSection
                ingredientsSection
                resultSection

                Button {
                    showSaveSheet = true
                } label: {
                    Label("Als Rezept speichern", systemImage: "book.closed")
                }
                .buttonStyle(.rwPrimary)
                .disabled(meatKg <= 0)

                safetyBox
            }
            .padding(.horizontal, AppSpacing.screen)
            .padding(.top, AppSpacing.l)
            .padding(.bottom, AppSpacing.xxl)
        }
        .screenBackground()
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Wurst-Rechner")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadLists)
        .onChange(of: rows) { _, _ in saveLists() }
        .onChange(of: meats) { _, _ in saveLists() }
        .sheet(isPresented: $showSaveSheet) {
            SaveAsRecipeSheet(meats: meats, rows: rows) { title in
                saveConfirmation = "„\(title)“ wurde gespeichert — du findest es unter Rezepte in der Kategorie Wurst & Räuchern."
            }
        }
        .alert(
            "Als Rezept gespeichert",
            isPresented: Binding(
                get: { saveConfirmation != nil },
                set: { if !$0 { saveConfirmation = nil } }
            )
        ) {
            Button("Prima", role: .cancel) {}
        } message: {
            Text(saveConfirmation ?? "")
        }
    }

    // MARK: Abschnitte

    /// Der Fleisch-Mix: mehrere Sorten mit Gewicht und Anteil.
    private var meatSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            SectionHeaderView(title: "Fleisch")

            VStack(alignment: .leading, spacing: 0) {
                ForEach($meats) { $meat in
                    meatRow($meat)
                }

                Button {
                    meats.append(MeatRow())
                } label: {
                    Label("Fleischsorte hinzufügen", systemImage: "plus.circle.fill")
                        .font(AppTypography.secondary.weight(.medium))
                        .foregroundStyle(AppColors.copper)
                }
                .padding(.top, AppSpacing.m)

                HStack(alignment: .firstTextBaseline) {
                    Text("Fleisch gesamt")
                        .font(AppTypography.secondary)
                        .foregroundStyle(AppColors.textSecondary)
                    Spacer(minLength: AppSpacing.m)
                    Text(FormatHelpers.amountText(meatKg).map { "\($0) kg" } ?? "–")
                        .font(AppTypography.body.weight(.semibold))
                        .foregroundStyle(AppColors.textPrimary)
                }
                .padding(.top, AppSpacing.m)
            }
            .card()
        }
    }

    /// Eine Fleisch-Zeile: Löschen · Sorte · Gewicht · Anteil in Prozent.
    private func meatRow(_ meat: Binding<MeatRow>) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: AppSpacing.s) {
                Button {
                    meats.removeAll { $0.id == meat.wrappedValue.id }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(AppColors.textSecondary.opacity(0.55))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Fleischsorte entfernen")

                TextField("Sorte, z. B. Schweineschulter", text: meat.name)
                    .font(AppTypography.secondary)

                TextField("–", text: meat.kilogramsText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 52)

                Text("kg")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)

                Text(shareText(for: meat.wrappedValue))
                    .font(AppTypography.caption.weight(.medium))
                    .foregroundStyle(AppColors.copper)
                    .frame(width: 48, alignment: .trailing)
            }
            .padding(.vertical, AppSpacing.s)

            Divider()
                .overlay(AppColors.separator.opacity(0.6))
        }
    }

    /// Die Zutaten-Zeilen samt Vorlagen-Menü.
    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            HStack(alignment: .firstTextBaseline) {
                SectionHeaderView(title: "Zutaten je Kilogramm")

                Menu {
                    ForEach(Self.templates) { template in
                        Button(template.name) { load(template) }
                    }
                } label: {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "tray.and.arrow.down")
                        Text("Vorlage")
                    }
                    .font(AppTypography.secondary.weight(.medium))
                    .foregroundStyle(AppColors.copper)
                }
            }

            if let templateNote {
                Text(templateNote)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            VStack(alignment: .leading, spacing: 0) {
                ForEach($rows) { $row in
                    ingredientRow($row)
                }

                Button {
                    rows.append(CalculatorRow())
                } label: {
                    Label("Zutat hinzufügen", systemImage: "plus.circle.fill")
                        .font(AppTypography.secondary.weight(.medium))
                        .foregroundStyle(AppColors.copper)
                }
                .padding(.top, AppSpacing.m)
            }
            .card()
        }
    }

    /// Eine Zutaten-Zeile: Löschen · Name · g/kg-Eingabe · Ergebnis.
    private func ingredientRow(_ row: Binding<CalculatorRow>) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: AppSpacing.s) {
                Button {
                    rows.removeAll { $0.id == row.wrappedValue.id }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(AppColors.textSecondary.opacity(0.55))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Zutat entfernen")

                TextField("Zutat", text: row.name)
                    .font(AppTypography.secondary)

                TextField("–", text: row.gramsPerKgText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 52)

                Text("g/kg")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)

                Text(resultText(for: row.wrappedValue))
                    .font(AppTypography.body.weight(.medium))
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(width: 76, alignment: .trailing)
            }
            .padding(.vertical, AppSpacing.s)

            Divider()
                .overlay(AppColors.separator.opacity(0.6))
        }
    }

    /// Die Summenzeilen.
    private var resultSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            SectionHeaderView(title: "Ergebnis")

            VStack(alignment: .leading, spacing: 0) {
                resultRow("Zutaten gesamt",
                          FormatHelpers.amountText(totalIngredientGrams).map { "\($0) g" } ?? "–")

                let totalMassKg = meatKg + totalIngredientGrams / 1000
                resultRow("Gesamtmasse (Fleisch + Zutaten)",
                          FormatHelpers.amountText(totalMassKg).map { "\($0) kg" } ?? "–")
            }
            .card()
        }
    }

    private func resultRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(label)
                    .font(AppTypography.secondary)
                    .foregroundStyle(AppColors.textSecondary)
                Spacer(minLength: AppSpacing.m)
                Text(value)
                    .font(AppTypography.body.weight(.medium))
                    .foregroundStyle(AppColors.textPrimary)
            }
            .padding(.vertical, AppSpacing.s)

            Divider()
                .overlay(AppColors.separator.opacity(0.6))
        }
    }

    /// Sicherheits-Hinweis (Muster: Sicherheits-Box der Fachdaten).
    private var safetyBox: some View {
        HStack(alignment: .top, spacing: AppSpacing.m) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 20))
                .foregroundStyle(AppColors.copper)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Sicherheit")
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(AppColors.textPrimary)
                Text("Die Vorlagen sind übliche Richtwerte — maßgeblich ist deine eigene, erprobte Rezeptur. Nitritpökelsalz grammgenau abwiegen und die Kühlkette einhalten.")
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

    // MARK: Rechnen & Merken

    /// Gramm für eine Zutaten-Zeile beim aktuellen Gesamt-Fleischgewicht.
    private func grams(for row: CalculatorRow) -> Double {
        (FormatHelpers.parseAmount(row.gramsPerKgText) ?? 0) * meatKg
    }

    /// Ergebnis-Text einer Zutaten-Zeile, z. B. „45 g“.
    private func resultText(for row: CalculatorRow) -> String {
        FormatHelpers.amountText(grams(for: row)).map { "\($0) g" } ?? "–"
    }

    /// Anteil einer Fleischsorte am Gesamtgewicht, z. B. „60 %“.
    private func shareText(for meat: MeatRow) -> String {
        let kg = FormatHelpers.parseAmount(meat.kilogramsText) ?? 0
        guard kg > 0, meatKg > 0 else { return "" }
        return "\(Int((kg / meatKg * 100).rounded())) %"
    }

    /// Lädt eine Vorlage (mit frischen Zeilen-IDs).
    private func load(_ template: SausageTemplate) {
        rows = template.rows.map {
            CalculatorRow(name: $0.name, gramsPerKgText: $0.gramsPerKgText)
        }
        templateNote = template.note
    }

    /// Stellt die gemerkten Listen wieder her — beim allerersten Öffnen
    /// wird die Brühwurst-Vorlage geladen und eine leere Fleisch-Zeile
    /// angelegt.
    private func loadLists() {
        if meats.isEmpty {
            if let data = savedMeatsJSON.data(using: .utf8),
               let saved = try? JSONDecoder().decode([MeatRow].self, from: data),
               !saved.isEmpty {
                meats = saved
            } else {
                meats = [MeatRow()]
            }
        }

        if rows.isEmpty {
            if let data = savedRowsJSON.data(using: .utf8),
               let saved = try? JSONDecoder().decode([CalculatorRow].self, from: data),
               !saved.isEmpty {
                rows = saved
            } else if let first = Self.templates.first {
                load(first)
            }
        }
    }

    /// Merkt sich Fleisch- und Zutatenliste.
    private func saveLists() {
        if let data = try? JSONEncoder().encode(rows),
           let json = String(data: data, encoding: .utf8) {
            savedRowsJSON = json
        }
        if let data = try? JSONEncoder().encode(meats),
           let json = String(data: data, encoding: .utf8) {
            savedMeatsJSON = json
        }
    }

    // MARK: Rezept bauen

    /// Baut aus dem Rechner-Stand einen Rezept-Entwurf: Fleisch und die
    /// fertig berechneten Zutatenmengen als Zutatenliste, dazu die
    /// Fachdaten (Fleischmenge, NPS je kg, Gewürze je kg) und die
    /// Kategorie „Wurst & Räuchern“.
    static func makeDraft(
        title: String,
        meats: [MeatRow],
        rows: [CalculatorRow],
        categories: [RecipeCategory]
    ) -> RecipeDraft {
        let draft = RecipeDraft()
        draft.title = title
        draft.servings = 1
        draft.sourceText = "Aus dem Wurst-Rechner (\(FormatHelpers.shortDate(.now)))"
        draft.category = categories.first { $0.isSausageSmokingCategory }

        let totalKg = meats.reduce(0) { $0 + (FormatHelpers.parseAmount($1.kilogramsText) ?? 0) }

        // Zutatenliste: erst das Fleisch (kg), dann die berechneten Mengen (g).
        var ingredients: [DraftIngredient] = []
        for meat in meats {
            let name = meat.name.trimmingCharacters(in: .whitespaces)
            guard let kg = FormatHelpers.parseAmount(meat.kilogramsText), kg > 0 else { continue }
            var item = DraftIngredient()
            item.amountText = FormatHelpers.amountText(kg) ?? ""
            item.unit = "kg"
            item.name = name.isEmpty ? "Fleisch" : name
            ingredients.append(item)
        }
        for row in rows {
            let name = row.name.trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty,
                  let perKg = FormatHelpers.parseAmount(row.gramsPerKgText), perKg > 0
            else { continue }
            var item = DraftIngredient()
            item.amountText = FormatHelpers.amountText(perKg * totalKg) ?? ""
            item.unit = "g"
            item.name = name
            ingredients.append(item)
        }
        if !ingredients.isEmpty {
            draft.ingredients = ingredients
        }

        // Fachdaten: Fleischmenge, NPS je kg und die übrigen Gewürze je kg.
        draft.includeSausageDetails = true
        draft.meatWeightText = FormatHelpers.amountText(totalKg) ?? ""

        let npsRow = rows.first {
            $0.name.localizedCaseInsensitiveContains("nitritpökelsalz")
                || $0.name.localizedCaseInsensitiveContains("nps")
        }
        if let npsRow {
            draft.npsText = npsRow.gramsPerKgText
        }

        let seasoning = rows
            .filter { $0.id != npsRow?.id }
            .compactMap { row -> String? in
                let name = row.name.trimmingCharacters(in: .whitespaces)
                guard !name.isEmpty,
                      let perKg = FormatHelpers.parseAmount(row.gramsPerKgText), perKg > 0,
                      let amount = FormatHelpers.amountText(perKg)
                else { return nil }
                return "\(amount) g \(name)"
            }
            .joined(separator: ", ")
        draft.seasoningPerKg = seasoning

        return draft
    }
}

/// Kleines Blatt: Name eingeben → der Rechner-Stand wird als Rezept
/// gespeichert.
private struct SaveAsRecipeSheet: View {

    let meats: [MeatRow]
    let rows: [CalculatorRow]
    /// Wird nach erfolgreichem Speichern mit dem Titel aufgerufen.
    let onSaved: (String) -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespaces)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Wie soll das Rezept heißen?") {
                    TextField("z. B. Hausmacher Bratwurst", text: $title)
                }

                Section {
                    Text("Gespeichert werden der Fleisch-Mix, die berechneten Zutatenmengen und die Fachdaten (NPS und Gewürze je kg) — in der Kategorie „Wurst & Räuchern“.")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .navigationTitle("Als Rezept speichern")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        let categories = (try? modelContext.fetch(
                            FetchDescriptor<RecipeCategory>()
                        )) ?? []
                        let draft = WurstRechnerView.makeDraft(
                            title: trimmedTitle,
                            meats: meats,
                            rows: rows,
                            categories: categories
                        )
                        guard (try? RecipeImportService.save(
                            draft: draft, updating: nil, in: modelContext
                        )) != nil else { return }
                        dismiss()
                        onSaved(trimmedTitle)
                    }
                    .disabled(trimmedTitle.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    NavigationStack {
        WurstRechnerView()
    }
    .modelContainer(PreviewSupport.container)
}
