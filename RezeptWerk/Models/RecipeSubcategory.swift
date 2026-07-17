import Foundation
import SwiftData

/// Eine Unterkategorie, z. B. „Grillen → Dutch Oven“.
@Model
final class RecipeSubcategory {

    var name: String = ""

    /// Reihenfolge innerhalb der Hauptkategorie.
    var sortIndex: Int = 0

    /// Rückverweis auf die Hauptkategorie.
    /// Die `inverse`-Deklaration liegt bei `RecipeCategory.subcategories`.
    var category: RecipeCategory?

    /// Rezepte dieser Unterkategorie. Beim Löschen bleiben die Rezepte
    /// erhalten (nullify). Optional wegen CloudKit.
    @Relationship(deleteRule: .nullify, inverse: \Recipe.subcategory)
    var recipes: [Recipe]?

    init(name: String, sortIndex: Int = 0) {
        self.name = name
        self.sortIndex = sortIndex
    }
}
