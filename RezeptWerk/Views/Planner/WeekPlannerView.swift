import SwiftUI
import SwiftData

/// Der Wochenplaner: sieben Tageskarten, in die Rezepte zu Mahlzeiten
/// (Frühstück/Mittag/Abend/Snack) eingeplant werden.
///
/// Wichtig: Diese View bringt **keinen** eigenen `NavigationStack` mit. Sie
/// lebt entweder im Stack des Dashboards (iPhone, per `NavigationLink`) oder
/// im Stack des iPad-Tabs (siehe `RootView`). Beide stellen das
/// `navigationDestination(for: PlannedMeal.self)` bereit — ein geplantes
/// Gericht öffnet die Detailansicht mit seinen geplanten Portionen.
struct WeekPlannerView: View {

    @Query(sort: \PlannedMeal.sortIndex)
    private var allMeals: [PlannedMeal]

    @Environment(\.modelContext) private var modelContext

    /// Verschiebung in Wochen relativ zur aktuellen Woche (0 = diese Woche).
    @State private var weekOffset = 0
    /// Tag, für den gerade ein Gericht eingeplant wird (steuert das Sheet).
    @State private var dayToPlan: Date?
    /// Planeintrag, dessen Portionen gerade geändert werden (steuert das Sheet).
    @State private var mealToAdjust: PlannedMeal?
    @State private var saveFailed = false

    /// Montag-basierter Kalender (deutsche Wochenführung).
    private var calendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Montag
        return calendar
    }

    /// Beginn (Montag) der angezeigten Woche.
    private var weekStart: Date {
        let base = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: .now) ?? .now
        return calendar.dateInterval(of: .weekOfYear, for: base)?.start ?? base
    }

    private var days: [Date] {
        (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.l) {
                weekSwitcher

                ForEach(days, id: \.self) { day in
                    dayCard(for: day)
                }
            }
            .padding(.horizontal, AppSpacing.screen)
            .padding(.vertical, AppSpacing.l)
        }
        .screenBackground()
        .navigationTitle("Wochenplan")
        .navigationBarTitleDisplayMode(.inline)
        .saveErrorAlert($saveFailed)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Heute") { weekOffset = 0 }
                    .disabled(weekOffset == 0)
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    ShoppingListView()
                } label: {
                    Label("Einkaufsliste", systemImage: "cart")
                }
            }
        }
        .sheet(item: planningSheetBinding) { day in
            PlanMealSheet(date: day.date)
        }
        .sheet(item: $mealToAdjust) { meal in
            MealServingsSheet(meal: meal)
        }
    }

    // MARK: Wochen-Umschalter

    private var weekSwitcher: some View {
        HStack {
            Button {
                weekOffset -= 1
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .foregroundStyle(AppColors.copper)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            VStack(spacing: 2) {
                Text(weekRangeText)
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(AppColors.textPrimary)
                if weekOffset == 0 {
                    Text("Diese Woche")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.copper)
                }
            }

            Spacer()

            Button {
                weekOffset += 1
            } label: {
                Image(systemName: "chevron.right")
                    .font(.headline)
                    .foregroundStyle(AppColors.copper)
                    .frame(width: 44, height: 44)
            }
        }
        .card(padding: AppSpacing.s)
    }

    private var weekRangeText: String {
        guard let last = days.last else { return "" }
        let start = weekStart.formatted(.dateTime.day().month(.abbreviated))
        let end = last.formatted(.dateTime.day().month(.abbreviated))
        return "\(start) – \(end)"
    }

    // MARK: Tageskarte

    private func dayCard(for day: Date) -> some View {
        let meals = meals(for: day)
        let isToday = calendar.isDateInToday(day)

        return VStack(alignment: .leading, spacing: AppSpacing.m) {
            HStack(alignment: .firstTextBaseline) {
                Text(day.formatted(.dateTime.weekday(.wide)))
                    .font(AppTypography.sectionTitle)
                    .foregroundStyle(isToday ? AppColors.copper : AppColors.textPrimary)
                Text(day.formatted(.dateTime.day().month()))
                    .font(AppTypography.secondary)
                    .foregroundStyle(AppColors.textSecondary)
                Spacer()
                if isToday {
                    Text("Heute")
                        .font(AppTypography.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, AppSpacing.s)
                        .padding(.vertical, 3)
                        .background(AppColors.copper, in: Capsule())
                }
            }

            if meals.isEmpty {
                Text("Noch nichts geplant")
                    .font(AppTypography.secondary)
                    .foregroundStyle(AppColors.textSecondary)
            } else {
                ForEach(meals) { meal in
                    plannedRow(meal)
                    if meal.id != meals.last?.id {
                        Divider().overlay(AppColors.separator.opacity(0.6))
                    }
                }
            }

            Button {
                dayToPlan = day
            } label: {
                Label("Gericht planen", systemImage: "plus.circle.fill")
                    .font(AppTypography.secondary.weight(.medium))
                    .foregroundStyle(AppColors.copper)
            }
            .padding(.top, AppSpacing.xs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .strokeBorder(isToday ? AppColors.copper.opacity(0.5) : Color.clear, lineWidth: 1.5)
        )
    }

    /// Eine geplante Mahlzeit: Mahlzeit-Badge + Rezept (antippbar) +
    /// Portionen (antippbar) + Entfernen.
    private func plannedRow(_ meal: PlannedMeal) -> some View {
        HStack(spacing: AppSpacing.m) {
            if let recipe = meal.recipe {
                // Ziel ist der Planeintrag, nicht das Rezept: So startet
                // die Detailansicht gleich mit den geplanten Portionen.
                NavigationLink(value: meal) {
                    HStack(spacing: AppSpacing.m) {
                        RecipeImageView(
                            data: recipe.coverImageData,
                            placeholderIcon: recipe.category?.iconName ?? "fork.knife"
                        )
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous))

                        VStack(alignment: .leading, spacing: 2) {
                            Label(meal.mealType.label, systemImage: meal.mealType.icon)
                                .font(AppTypography.caption.weight(.semibold))
                                .foregroundStyle(AppColors.copper)
                            Text(recipe.title)
                                .font(AppTypography.body.weight(.medium))
                                .foregroundStyle(AppColors.textPrimary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }
                    }
                }
                .buttonStyle(.plain)
            } else {
                // Rezept wurde gelöscht — Eintrag aufräumbar anzeigen.
                Text("\(meal.mealType.label): Rezept nicht mehr vorhanden")
                    .font(AppTypography.secondary)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer(minLength: 0)

            if meal.recipe != nil {
                Button {
                    mealToAdjust = meal
                } label: {
                    Label("\(meal.effectiveServings)", systemImage: "person.2")
                        .font(AppTypography.caption.weight(.semibold))
                        .foregroundStyle(AppColors.copper)
                        .padding(.horizontal, AppSpacing.s)
                        .padding(.vertical, 5)
                        .background(AppColors.backgroundSunken, in: Capsule())
                        .overlay(Capsule().strokeBorder(AppColors.separator, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(meal.effectiveServings) Portionen, ändern")
            }

            Button {
                remove(meal)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(AppColors.textSecondary.opacity(0.7))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Aus Plan entfernen")
        }
        .padding(.vertical, AppSpacing.xs)
    }

    // MARK: Daten

    /// Geplante Mahlzeiten eines Tages, nach Mahlzeit-Typ sortiert.
    private func meals(for day: Date) -> [PlannedMeal] {
        allMeals
            .filter { calendar.isDate($0.date, inSameDayAs: day) }
            .sorted {
                ($0.mealType.sortOrder, $0.sortIndex) < ($1.mealType.sortOrder, $1.sortIndex)
            }
    }

    private func remove(_ meal: PlannedMeal) {
        modelContext.delete(meal)
        do {
            try modelContext.save()
        } catch {
            // Nicht gespeichert: Löschen zurücknehmen und Bescheid geben.
            modelContext.rollback()
            saveFailed = true
            return
        }
        // Homescreen-Widget auf den neuen Stand bringen.
        WidgetPlanSync.refresh(context: modelContext)
    }

    /// Brückt das `Date?` für `sheet(item:)` (Date selbst ist nicht
    /// `Identifiable`).
    private var planningSheetBinding: Binding<IdentifiableDate?> {
        Binding(
            get: { dayToPlan.map(IdentifiableDate.init) },
            set: { dayToPlan = $0?.date }
        )
    }
}

/// Kleiner Wrapper, damit ein `Date` in `sheet(item:)` verwendet werden kann.
struct IdentifiableDate: Identifiable {
    let date: Date
    var id: TimeInterval { date.timeIntervalSince1970 }
}

#Preview {
    NavigationStack {
        WeekPlannerView()
            .navigationDestination(for: PlannedMeal.self) { meal in
                if let recipe = meal.recipe {
                    RecipeDetailView(recipe: recipe, initialServings: meal.effectiveServings)
                }
            }
    }
    .modelContainer(PreviewSupport.container)
}
