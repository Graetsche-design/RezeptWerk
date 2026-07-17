import Foundation
import SwiftData

/// Ein Eintrag im Wochenplan: „An diesem Tag, zu dieser Mahlzeit, dieses
/// Rezept.“
///
/// `date` wird immer auf den Tagesanfang normalisiert (00:00 Uhr), damit
/// das Gruppieren nach Tag zuverlässig funktioniert.
@Model
final class PlannedMeal {

    /// Der geplante Tag (auf 00:00 Uhr normalisiert).
    var date: Date = Date.now

    /// Mahlzeit-Typ als Rohwert gespeichert (robust für SwiftData).
    var mealTypeRaw: String = MealType.dinner.rawValue

    /// Reihenfolge innerhalb derselben Mahlzeit an einem Tag.
    var sortIndex: Int = 0

    var createdAt: Date = Date.now

    /// Das geplante Rezept. Optional (CloudKit-Voraussetzung); die
    /// `inverse`-Deklaration liegt bei `Recipe.plannedMeals`, von wo aus
    /// das Löschen eines Rezepts auch seine Planeinträge entfernt (cascade).
    var recipe: Recipe?

    init(date: Date, mealType: MealType, recipe: Recipe?, sortIndex: Int = 0) {
        self.date = date
        self.mealTypeRaw = mealType.rawValue
        self.recipe = recipe
        self.sortIndex = sortIndex
    }

    var mealType: MealType {
        get { MealType(rawValue: mealTypeRaw) ?? .dinner }
        set { mealTypeRaw = newValue.rawValue }
    }
}
