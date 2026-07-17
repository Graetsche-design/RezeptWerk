import Foundation
import SwiftData

/// Legt beim ersten Start die Standard-Kategorien und Beispielrezepte an.
///
/// Außerdem: „Beispielrezepte neu laden“ (Einstellungen) — ersetzt nur die
/// mitgelieferten Beispiele (`isSample == true`), eigene Rezepte bleiben
/// selbstverständlich unangetastet.
@MainActor
enum SampleDataService {

    /// Wird bei jedem App-Start aufgerufen — legt nur an, was fehlt.
    static func seedIfNeeded(context: ModelContext) {
        seedCategoriesIfNeeded(context: context)
        seedRecipesIfNeeded(context: context)
    }

    /// Standard-Kategorien anlegen, falls noch gar keine existieren.
    private static func seedCategoriesIfNeeded(context: ModelContext) {
        let existingCount = (try? context.fetchCount(FetchDescriptor<RecipeCategory>())) ?? 0
        guard existingCount == 0 else { return }

        for (index, blueprint) in DefaultCategories.all.enumerated() {
            let category = RecipeCategory(
                name: blueprint.name,
                iconName: blueprint.icon,
                sortIndex: index,
                isBuiltIn: true
            )
            context.insert(category)
            category.subcategories = blueprint.subcategories.enumerated().map { subIndex, subName in
                RecipeSubcategory(name: subName, sortIndex: subIndex)
            }
        }
        try? context.save()
    }

    /// Beispielrezepte anlegen, falls die Rezeptliste komplett leer ist.
    private static func seedRecipesIfNeeded(context: ModelContext) {
        let existingCount = (try? context.fetchCount(FetchDescriptor<Recipe>())) ?? 0
        guard existingCount == 0 else { return }

        SampleRecipes.insert(into: context)
        try? context.save()
    }

    /// Einstellungen → „Beispielrezepte neu laden“:
    /// Löscht nur die Beispiele und legt sie frisch an.
    static func reloadSampleRecipes(context: ModelContext) {
        let allRecipes = (try? context.fetch(FetchDescriptor<Recipe>())) ?? []
        for recipe in allRecipes where recipe.isSample {
            context.delete(recipe)
        }
        SampleRecipes.insert(into: context)
        try? context.save()
    }
}
