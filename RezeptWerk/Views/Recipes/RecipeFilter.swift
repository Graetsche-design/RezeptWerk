import Foundation

/// Filter- und Suchlogik der Rezeptliste — an einer Stelle gebündelt.
///
/// Die Filterung läuft bewusst **im Speicher** statt über SwiftData-
/// Predicates: Bei einer persönlichen Rezeptsammlung (auch mit hunderten
/// Rezepten) ist das verzögerungsfrei, und es umgeht die Einschränkungen
/// von `#Predicate` bei optionalen Beziehungen und n:m-Tags — eine der
/// häufigsten SwiftData-Fehlerquellen.
struct RecipeFilter: Equatable {

    var category: RecipeCategory?
    var subcategory: RecipeSubcategory?
    var tagNames: Set<String> = []
    var difficulty: Difficulty?
    var onlyFavorites = false
    var sortOrder: SortOrder = .newest

    enum SortOrder: String, CaseIterable, Identifiable {
        case newest
        case title
        case rating

        var id: String { rawValue }

        var label: String {
            switch self {
            case .newest: "Neueste zuerst"
            case .title: "Titel A–Z"
            case .rating: "Beste Bewertung"
            }
        }
    }

    /// Ist mindestens ein Filter aktiv? (Sortierung zählt nicht.)
    var isActive: Bool {
        activeCount > 0
    }

    /// Anzahl aktiver Filter — für das Badge am Filter-Button.
    var activeCount: Int {
        var count = 0
        if category != nil { count += 1 }
        if subcategory != nil { count += 1 }
        if difficulty != nil { count += 1 }
        if onlyFavorites { count += 1 }
        count += tagNames.count
        return count
    }

    /// Alle Filter zurücksetzen, Sortierung beibehalten.
    mutating func reset() {
        self = RecipeFilter(sortOrder: sortOrder)
    }

    // MARK: Anwenden

    /// Filtert, durchsucht und sortiert die Rezeptliste.
    func apply(to recipes: [Recipe], searchText: String) -> [Recipe] {
        var result = recipes

        if let category {
            result = result.filter { $0.category === category }
        }
        if let subcategory {
            result = result.filter { $0.subcategory === subcategory }
        }
        if let difficulty {
            result = result.filter { $0.difficulty == difficulty }
        }
        if onlyFavorites {
            result = result.filter(\.isFavorite)
        }
        if !tagNames.isEmpty {
            // Treffer, sobald mindestens ein gewähltes Tag am Rezept hängt.
            result = result.filter { recipe in
                !tagNames.isDisjoint(with: Set(recipe.tagNames))
            }
        }

        let query = searchText.trimmingCharacters(in: .whitespaces)
        if !query.isEmpty {
            result = result.filter { matches($0, query: query) }
        }

        switch sortOrder {
        case .newest:
            result.sort { $0.createdAt > $1.createdAt }
        case .title:
            result.sort { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
        case .rating:
            result.sort { ($0.rating, $1.createdAt.timeIntervalSince1970) > ($1.rating, $0.createdAt.timeIntervalSince1970) }
        }

        return result
    }

    /// Volltextsuche über Titel, Kategorie, Tags, Zutaten und Notizen.
    private func matches(_ recipe: Recipe, query: String) -> Bool {
        if recipe.title.localizedCaseInsensitiveContains(query) { return true }
        if let categoryName = recipe.category?.name,
           categoryName.localizedCaseInsensitiveContains(query) { return true }
        if recipe.tagNames.contains(where: { $0.localizedCaseInsensitiveContains(query) }) { return true }
        if recipe.ingredientList.contains(where: { $0.name.localizedCaseInsensitiveContains(query) }) { return true }
        if recipe.notes.localizedCaseInsensitiveContains(query) { return true }
        return false
    }
}
