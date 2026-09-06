import SwiftUI
import SwiftData

/// Sheet zum Einplanen eines Rezepts: Mahlzeit-Typ wählen, Rezept suchen
/// und antippen — fertig.
struct PlanMealSheet: View {

    /// Der Tag, für den geplant wird.
    let date: Date

    @Query(sort: \Recipe.title)
    private var allRecipes: [Recipe]

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var mealType: MealType = .dinner
    @State private var searchText = ""
    /// Nur Rezepte zeigen, die zur gewählten Mahlzeit passen.
    @State private var onlySuitable = false
    @State private var saveFailed = false

    /// Portionen für den neuen Eintrag — wird gemerkt, weil die Zahl meist
    /// dem Haushalt entspricht. 0 = wie im Rezept.
    @AppStorage(SettingsKeys.plannerServings)
    private var plannerServings = 0

    /// Such-gefilterte, nach Eignung sortierte Rezeptliste.
    /// Für die gewählte Mahlzeit geeignete Rezepte stehen oben.
    private var displayedRecipes: [Recipe] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        var result = query.isEmpty
            ? allRecipes
            : allRecipes.filter { $0.title.localizedCaseInsensitiveContains(query) }

        if onlySuitable {
            // „Passend“ = ausdrücklich für die Mahlzeit markiert ODER ganz
            // ohne Angabe (passt überall).
            result = result.filter { !$0.hasMealTypePreference || $0.isSuitable(for: mealType) }
        }

        // Ausdrücklich geeignete zuerst, dann alphabetisch.
        return result.sorted { lhs, rhs in
            let lhsFit = lhs.isSuitable(for: mealType)
            let rhsFit = rhs.isSuitable(for: mealType)
            if lhsFit != rhsFit { return lhsFit }
            return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
        }
    }

    private var calendar: Calendar { Calendar.current }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Mahlzeit-Auswahl.
                Picker("Mahlzeit", selection: $mealType) {
                    ForEach(MealType.allCases) { type in
                        Text(type.shortLabel).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, AppSpacing.screen)
                .padding(.top, AppSpacing.screen)
                .padding(.bottom, AppSpacing.m)

                Toggle("Nur passende Rezepte", isOn: $onlySuitable)
                    .tint(AppColors.copper)
                    .font(AppTypography.secondary)
                    .padding(.horizontal, AppSpacing.screen)
                    .padding(.bottom, AppSpacing.s)

                // Portionen: Kochmodus und Einkaufsliste rechnen später damit.
                Stepper(value: $plannerServings, in: 0...50) {
                    Label(
                        plannerServings > 0
                            ? "\(plannerServings) Portionen"
                            : "Portionen wie im Rezept",
                        systemImage: "person.2"
                    )
                    .font(AppTypography.secondary)
                    .foregroundStyle(AppColors.textPrimary)
                }
                .padding(.horizontal, AppSpacing.screen)
                .padding(.bottom, AppSpacing.m)

                Divider()

                if allRecipes.isEmpty {
                    EmptyStateView(
                        icon: "book.closed",
                        title: "Noch keine Rezepte",
                        message: "Lege zuerst ein Rezept an, dann kannst du es in den Wochenplan aufnehmen."
                    )
                } else {
                    recipeList
                }
            }
            .screenBackground()
            .navigationTitle(planTitle)
            .navigationBarTitleDisplayMode(.inline)
            .saveErrorAlert($saveFailed)
            .searchable(text: $searchText, prompt: "Rezept suchen …")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
            }
        }
    }

    private var planTitle: String {
        date.formatted(.dateTime.weekday(.wide).day().month())
    }

    private var recipeList: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.s) {
                ForEach(displayedRecipes) { recipe in
                    Button {
                        plan(recipe)
                    } label: {
                        HStack(spacing: AppSpacing.m) {
                            RecipeImageView(
                                data: recipe.coverImageData,
                                placeholderIcon: recipe.category?.iconName ?? "fork.knife"
                            )
                            .frame(width: 54, height: 54)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(recipe.title)
                                    .font(AppTypography.body.weight(.medium))
                                    .foregroundStyle(AppColors.textPrimary)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)

                                HStack(spacing: AppSpacing.xs) {
                                    if recipe.isSuitable(for: mealType) {
                                        Label("Geeignet", systemImage: "checkmark.circle.fill")
                                            .font(AppTypography.caption.weight(.semibold))
                                            .foregroundStyle(AppColors.copper)
                                    }
                                    Text(rowDetails(for: recipe))
                                        .font(AppTypography.caption)
                                        .foregroundStyle(AppColors.textSecondary)
                                }
                            }

                            Spacer(minLength: 0)

                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(AppColors.copper)
                        }
                        .card(padding: AppSpacing.s)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppSpacing.screen)
            .padding(.vertical, AppSpacing.l)
        }
    }

    /// „Hauptgerichte · 4 Portionen“ — die Rezept-Portionen stehen dabei,
    /// damit „Portionen wie im Rezept“ greifbar bleibt.
    private func rowDetails(for recipe: Recipe) -> String {
        [recipe.category?.name, "\(recipe.servings) Portionen"]
            .compactMap { $0 }
            .joined(separator: " · ")
    }

    private func plan(_ recipe: Recipe) {
        let normalizedDay = calendar.startOfDay(for: date)
        // sortIndex = bisherige Anzahl gleicher Mahlzeit an dem Tag.
        let existing = ((try? modelContext.fetch(FetchDescriptor<PlannedMeal>())) ?? [])
            .filter {
                calendar.isDate($0.date, inSameDayAs: normalizedDay)
                    && $0.mealTypeRaw == mealType.rawValue
            }
        let meal = PlannedMeal(
            date: normalizedDay,
            mealType: mealType,
            recipe: recipe,
            sortIndex: existing.count,
            servings: plannerServings
        )
        modelContext.insert(meal)
        do {
            try modelContext.save()
        } catch {
            // Nicht gespeichert: Einfügen zurücknehmen und Bescheid geben —
            // das Blatt bleibt offen, der Nutzer kann es erneut versuchen.
            modelContext.rollback()
            saveFailed = true
            return
        }
        // Homescreen-Widget auf den neuen Stand bringen.
        WidgetPlanSync.refresh(context: modelContext)
        dismiss()
    }
}
