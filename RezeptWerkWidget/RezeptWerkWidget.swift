import WidgetKit
import SwiftUI

// MARK: - Datenvertrag zur App

/// Eine geplante Mahlzeit aus dem Schnappschuss der App.
///
/// **Wichtig:** Muss 1:1 zu `RezeptWerk/App/WidgetPlanSync.swift` passen —
/// das JSON in der App-Gruppe ist der Vertrag zwischen App und Widget.
/// (Die Datei kann nicht geteilt werden, weil jeder synchronisierte Ordner
/// genau einem Target gehört.)
struct WidgetMeal: Codable {
    let day: Date
    let sortOrder: Int
    let label: String
    let icon: String
    let recipeTitle: String
}

/// Der komplette Schnappschuss (heute + 6 Folgetage).
struct WidgetPlanSnapshot: Codable {
    let createdAt: Date
    let meals: [WidgetMeal]
}

// MARK: - Farben

/// RezeptWerk-Farben als feste Werte. Der Asset-Katalog der App ist im
/// Widget nicht verfügbar — darum hier die Dunkel-Varianten als Literale
/// (bewusst fester Dunkel-Look, wie Kochmodus und Teilen-Erweiterung).
enum WidgetColors {
    static let anthrazit = Color(red: 0.106, green: 0.090, blue: 0.075)
    static let kupfer    = Color(red: 0.851, green: 0.502, blue: 0.239)
    static let creme     = Color(red: 0.941, green: 0.910, blue: 0.851)
    static let nebentext = Color(red: 0.663, green: 0.608, blue: 0.522)
}

// MARK: - Zeitachse

/// Ein Anzeigestand des Widgets: die Mahlzeiten EINES Tages.
struct PlanEntry: TimelineEntry {
    let date: Date
    let meals: [WidgetMeal]
}

/// Liefert dem System die Anzeigestände: einen für jetzt und je einen ab
/// Mitternacht der Folgetage — so wechselt das Widget um Mitternacht von
/// selbst auf den nächsten Tag, ohne dass die App laufen muss.
struct PlanTimelineProvider: TimelineProvider {

    private let appGroupID = "group.de.rezeptwerk.app"
    private let snapshotKey = "widgetPlanSnapshot"

    /// Platzhalter für die Widget-Galerie.
    func placeholder(in context: Context) -> PlanEntry {
        PlanEntry(date: .now, meals: sampleMeals())
    }

    func getSnapshot(in context: Context, completion: @escaping (PlanEntry) -> Void) {
        let loaded = loadSnapshot()?.meals ?? sampleMeals()
        completion(PlanEntry(date: .now, meals: meals(on: .now, from: loaded)))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PlanEntry>) -> Void) {
        let all = loadSnapshot()?.meals ?? []
        let calendar = Calendar.current
        var entries: [PlanEntry] = []

        // Heute (ab jetzt) + die nächsten 6 Tage (ab je Mitternacht).
        for offset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: offset,
                                          to: calendar.startOfDay(for: .now))
            else { continue }
            let entryDate = offset == 0 ? Date.now : day
            entries.append(PlanEntry(date: entryDate, meals: meals(on: day, from: all)))
        }

        completion(Timeline(entries: entries, policy: .atEnd))
    }

    /// Liest den Schnappschuss der App aus der gemeinsamen App-Gruppe.
    private func loadSnapshot() -> WidgetPlanSnapshot? {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: snapshotKey) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(WidgetPlanSnapshot.self, from: data)
    }

    /// Die Mahlzeiten eines bestimmten Kalendertags.
    private func meals(on day: Date, from all: [WidgetMeal]) -> [WidgetMeal] {
        all.filter { Calendar.current.isDate($0.day, inSameDayAs: day) }
    }

    /// Beispieldaten für Galerie und Vorschau.
    private func sampleMeals() -> [WidgetMeal] {
        [
            WidgetMeal(day: .now, sortOrder: 1, label: "Mittagessen",
                       icon: "sun.max", recipeTitle: "Kinder-Pasta mit Tomatensauce"),
            WidgetMeal(day: .now, sortOrder: 2, label: "Abendessen",
                       icon: "moon.stars", recipeTitle: "Rib-Eye-Steak vom Grill"),
        ]
    }
}

// MARK: - Ansicht

/// Die Widget-Oberfläche im RezeptWerk-Look: dunkler Grund, Serifen-Titel,
/// kupferner Unterstrich — wie eine kleine Kochbuchseite.
struct PlanWidgetView: View {

    let entry: PlanEntry

    @Environment(\.widgetFamily) private var family

    /// Kleines Widget zeigt 2 Zeilen, mittleres 3.
    private var maxRows: Int {
        family == .systemSmall ? 2 : 3
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header

            if entry.meals.isEmpty {
                emptyState
            } else {
                mealRows
            }

            Spacer(minLength: 0)
        }
        .containerBackground(for: .widget) {
            WidgetColors.anthrazit
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Heute")
                .font(.system(.headline, design: .serif).weight(.semibold))
                .foregroundStyle(WidgetColors.creme)

            RoundedRectangle(cornerRadius: 1.5)
                .fill(WidgetColors.kupfer)
                .frame(width: 24, height: 3)
        }
    }

    private var mealRows: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(entry.meals.prefix(maxRows).enumerated()), id: \.offset) { _, meal in
                mealRow(meal)
            }

            if entry.meals.count > maxRows {
                Text("+ \(entry.meals.count - maxRows) weitere")
                    .font(.caption2)
                    .foregroundStyle(WidgetColors.nebentext)
            }
        }
    }

    private func mealRow(_ meal: WidgetMeal) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            if family != .systemSmall {
                Image(systemName: meal.icon)
                    .font(.caption2)
                    .foregroundStyle(WidgetColors.kupfer)
                    .frame(width: 14)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(meal.label)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(WidgetColors.kupfer)

                Text(meal.recipeTitle)
                    .font(.footnote)
                    .foregroundStyle(WidgetColors.creme)
                    .lineLimit(1)
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Nichts geplant")
                .font(.footnote)
                .foregroundStyle(WidgetColors.nebentext)
            Text("Plane deine Woche in RezeptWerk.")
                .font(.caption2)
                .foregroundStyle(WidgetColors.nebentext.opacity(0.8))
        }
    }
}

// MARK: - Widget-Definition

struct RezeptWerkTodayPlanWidget: Widget {

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "RezeptWerkTodayPlan", provider: PlanTimelineProvider()) { entry in
            PlanWidgetView(entry: entry)
        }
        .configurationDisplayName("Heute auf dem Wochenplan")
        .description("Zeigt die für heute geplanten Mahlzeiten aus RezeptWerk.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct RezeptWerkWidgetBundle: WidgetBundle {
    var body: some Widget {
        RezeptWerkTodayPlanWidget()
    }
}
