import Foundation
import SwiftData

/// Ein Eintrag im Wochenplan: „An diesem Tag, zu dieser Mahlzeit, dieses
/// Rezept — für so viele Portionen.“
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

    /// Geplante Portionen. 0 = „wie im Rezept“ — der Standard, der auch
    /// für Einträge aus Versionen vor 2.5 gilt, die diese Angabe noch
    /// nicht kannten (additive Migration).
    var servings: Int = 0

    /// Das geplante Rezept. Optional (CloudKit-Voraussetzung); die
    /// `inverse`-Deklaration liegt bei `Recipe.plannedMeals`, von wo aus
    /// das Löschen eines Rezepts auch seine Planeinträge entfernt (cascade).
    var recipe: Recipe?

    init(date: Date, mealType: MealType, recipe: Recipe?, sortIndex: Int = 0, servings: Int = 0) {
        self.date = date
        self.mealTypeRaw = mealType.rawValue
        self.recipe = recipe
        self.sortIndex = sortIndex
        self.servings = max(0, servings)
    }

    var mealType: MealType {
        get { MealType(rawValue: mealTypeRaw) ?? .dinner }
        set { mealTypeRaw = newValue.rawValue }
    }

    /// Die Portionen, für die tatsächlich gekocht und eingekauft wird:
    /// die geplante Zahl — oder, wenn keine gesetzt ist, die des Rezepts.
    var effectiveServings: Int {
        if servings > 0 { return servings }
        return max(1, recipe?.servings ?? 1)
    }

    /// Faktor, mit dem die Rezeptmengen für diesen Eintrag umgerechnet
    /// werden (Einkaufsliste, Kochmodus). 1, solange nichts abweicht.
    var scaleFactor: Double {
        recipe?.scaleFactor(forServings: servings > 0 ? servings : nil) ?? 1
    }
}
