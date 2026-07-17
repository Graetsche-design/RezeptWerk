import Foundation
import SwiftData
import WidgetKit

/// Ein Eintrag des Widget-Schnappschusses — eine geplante Mahlzeit.
///
/// Label und Symbol werden hier schon „fertig“ mitgegeben, damit das
/// Widget keine App-Typen (`MealType`, `Recipe`) kennen muss.
///
/// **Wichtig:** Muss 1:1 zur Kopie in `RezeptWerkWidget/RezeptWerkWidget.swift`
/// passen — das JSON in der App-Gruppe ist der Vertrag zwischen beiden.
struct WidgetMeal: Codable {
    /// Tagesanfang (00:00) des geplanten Tages.
    let day: Date
    /// Reihenfolge innerhalb des Tages (Frühstück → Snack).
    let sortOrder: Int
    /// Anzeigename der Mahlzeit, z. B. „Abendessen“.
    let label: String
    /// SF-Symbol der Mahlzeit, z. B. „moon.stars“.
    let icon: String
    /// Titel des geplanten Rezepts.
    let recipeTitle: String
}

/// Der komplette Schnappschuss für das Homescreen-Widget.
struct WidgetPlanSnapshot: Codable {
    let createdAt: Date
    /// Geplante Mahlzeiten von heute + 6 Folgetagen, fertig sortiert.
    let meals: [WidgetMeal]
}

/// Schreibt den Wochenplan-Schnappschuss in die App-Gruppe, damit das
/// Homescreen-Widget ihn lesen kann.
///
/// Hintergrund: Die SwiftData-Datenbank der App liegt **nicht** in der
/// App-Gruppe — das Widget kann sie nicht öffnen. Darum legt die App bei
/// jeder Plan-Änderung (und beim Aktivwerden) diese kleine JSON-Kopie ab
/// (gleiches Muster wie `SharedImportInbox`).
@MainActor
enum WidgetPlanSync {

    /// Gemeinsame App-Gruppe (wie `SharedImportInbox.appGroupID`).
    static let appGroupID = "group.de.rezeptwerk.app"

    /// Schlüssel des Schnappschusses in den App-Gruppen-UserDefaults.
    static let snapshotKey = "widgetPlanSnapshot"

    /// Schreibt den aktuellen Schnappschuss und weckt das Widget auf.
    /// Fehler werden bewusst still geschluckt — das Widget zeigt dann
    /// einfach den letzten Stand.
    static func refresh(context: ModelContext) {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: .now)
        guard let end = calendar.date(byAdding: .day, value: 7, to: start) else { return }

        let all = (try? context.fetch(FetchDescriptor<PlannedMeal>())) ?? []

        let meals = all
            .filter { $0.date >= start && $0.date < end }
            .sorted {
                if $0.date != $1.date { return $0.date < $1.date }
                if $0.mealType.sortOrder != $1.mealType.sortOrder {
                    return $0.mealType.sortOrder < $1.mealType.sortOrder
                }
                return $0.sortIndex < $1.sortIndex
            }
            .compactMap { meal -> WidgetMeal? in
                guard let title = meal.recipe?.title else { return nil }
                return WidgetMeal(
                    day: calendar.startOfDay(for: meal.date),
                    sortOrder: meal.mealType.sortOrder,
                    label: meal.mealType.label,
                    icon: meal.mealType.icon,
                    recipeTitle: title
                )
            }

        let snapshot = WidgetPlanSnapshot(createdAt: .now, meals: meals)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(snapshot),
              let defaults = UserDefaults(suiteName: appGroupID) else { return }

        defaults.set(data, forKey: snapshotKey)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
