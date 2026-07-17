import Foundation
import SwiftData

/// Eine Hauptkategorie, z. B. „Grillen“ oder „Wurst & Räuchern“.
///
/// Die zwölf Standard-Kategorien werden beim ersten Start angelegt
/// (`isBuiltIn = true`). Eigene Kategorien kann der Nutzer jederzeit
/// hinzufügen.
@Model
final class RecipeCategory {

    var name: String = ""

    /// SF-Symbol-Name für die Kategorie-Kachel, z. B. „flame“.
    var iconName: String = "fork.knife"

    /// Reihenfolge in Übersichten.
    var sortIndex: Int = 0

    /// `true` bei den mitgelieferten Standard-Kategorien.
    var isBuiltIn: Bool = false

    // To-many-Beziehungen sind optional (CloudKit-Voraussetzung).
    /// Unterkategorien — werden mit der Kategorie gelöscht (cascade).
    @Relationship(deleteRule: .cascade, inverse: \RecipeSubcategory.category)
    var subcategories: [RecipeSubcategory]?

    /// Rezepte dieser Kategorie. Beim Löschen der Kategorie bleiben die
    /// Rezepte erhalten und verlieren nur ihre Zuordnung (nullify).
    @Relationship(deleteRule: .nullify, inverse: \Recipe.category)
    var recipes: [Recipe]?

    init(name: String, iconName: String = "fork.knife", sortIndex: Int = 0, isBuiltIn: Bool = false) {
        self.name = name
        self.iconName = iconName
        self.sortIndex = sortIndex
        self.isBuiltIn = isBuiltIn
    }

    var sortedSubcategories: [RecipeSubcategory] {
        (subcategories ?? []).sorted { $0.sortIndex < $1.sortIndex }
    }

    /// Rezepte dieser Kategorie als normales Array (nie nil).
    var recipeList: [Recipe] {
        recipes ?? []
    }

    /// Kennzeichnet die Kategorie „Wurst & Räuchern“ — bei ihr blendet der
    /// Editor automatisch die Fachdaten-Felder ein.
    var isSausageSmokingCategory: Bool {
        name == "Wurst & Räuchern"
    }
}
