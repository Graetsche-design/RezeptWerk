import Testing
import SwiftData
import Foundation
@testable import RezeptWerk

/// Tests für die Spotlight-Anbindung: Kennzeichner-Roundtrip und
/// Suchinhalte (indiziert wird hier nichts).
@MainActor
struct SpotlightIndexServiceTests {

    /// Hält die Wegwerf-Container bis zum Prozessende am Leben:
    /// `mainContext` referenziert seinen Container nicht stark — ohne
    /// diesen Anker würde er am Funktionsende freigegeben und schon das
    /// nächste `insert` stürzt in SwiftData ab (Verhalten seit OS 26.5).
    private static var lebendeContainer: [ModelContainer] = []

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: ModelContainerFactory.schema,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        Self.lebendeContainer.append(container)
        return container.mainContext
    }

    private func makeRecipe(in context: ModelContext) throws -> Recipe {
        let category = RecipeCategory(name: "Fleisch", iconName: "flame", sortIndex: 0, isBuiltIn: true)
        context.insert(category)

        let recipe = Recipe(title: "Rinder-Gulasch")
        recipe.servings = 4
        recipe.cookMinutes = 90
        recipe.category = category
        recipe.ingredients = [
            Ingredient(amount: 800, unit: "g", name: "Rindfleisch", sortIndex: 0),
            Ingredient(amount: 2, unit: "", name: "Zwiebeln", sortIndex: 1),
        ]
        recipe.tags = [RecipeTag(name: "Schmoren")]
        context.insert(recipe)
        try context.save()
        return recipe
    }

    @Test func kennzeichnerFindetDasRezeptWieder() throws {
        let context = try makeContext()
        let recipe = try makeRecipe(in: context)

        let identifier = try #require(SpotlightIndexService.identifier(for: recipe))
        let gefunden = SpotlightIndexService.recipe(forSpotlightIdentifier: identifier, context: context)
        #expect(gefunden === recipe)
    }

    @Test func unbekannterKennzeichnerLiefertNil() throws {
        let context = try makeContext()
        _ = try makeRecipe(in: context)

        #expect(SpotlightIndexService.recipe(forSpotlightIdentifier: "kein json", context: context) == nil)
    }

    @Test func suchinhalteEnthaltenKategorieTagsUndZutaten() throws {
        let context = try makeContext()
        let recipe = try makeRecipe(in: context)

        let entry = try #require(SpotlightIndexService.entry(for: recipe))
        #expect(entry.title == "Rinder-Gulasch")
        #expect(entry.description == "Fleisch · 4 Portionen · 1 Std. 30 Min. — Rindfleisch, Zwiebeln")
        #expect(entry.keywords == ["Schmoren", "Rindfleisch", "Zwiebeln", "Fleisch"])
    }

    @Test func spotlightObjektTraegtKennzeichnerUndDomaene() throws {
        let context = try makeContext()
        let recipe = try makeRecipe(in: context)

        let entry = try #require(SpotlightIndexService.entry(for: recipe))
        let item = SpotlightIndexService.makeItem(entry)
        #expect(item.uniqueIdentifier == entry.identifier)
        #expect(item.domainIdentifier == SpotlightIndexService.domainIdentifier)
        #expect(item.attributeSet.title == "Rinder-Gulasch")
        #expect(item.attributeSet.keywords?.contains("Schmoren") == true)
    }

    @Test func rezeptOhneTitelWirdNichtIndiziert() throws {
        let context = try makeContext()
        let recipe = Recipe(title: "   ")
        context.insert(recipe)
        try context.save()

        #expect(SpotlightIndexService.entry(for: recipe) == nil)
    }
}
