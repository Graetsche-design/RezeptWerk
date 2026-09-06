import Testing
import SwiftData
import Foundation
@testable import RezeptWerk

/// Tests fürs Zusammenfassen der Einkaufsliste.
@MainActor
struct ShoppingListServiceTests {

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

    @Test func gleicheZutatWirdSummiert() throws {
        let context = try makeContext()
        let mehl = ShoppingListService.Entry(amount: 200, unit: "g", name: "Mehl")

        ShoppingListService.add(entries: [mehl], to: context)
        ShoppingListService.add(entries: [mehl], to: context)

        let items = try context.fetch(FetchDescriptor<ShoppingItem>())
        #expect(items.count == 1)
        #expect(items.first?.amount == 400)
    }

    @Test func verschiedeneEinheitenBleibenGetrennt() throws {
        let context = try makeContext()
        ShoppingListService.add(entries: [
            .init(amount: 200, unit: "g", name: "Mehl"),
            .init(amount: 1, unit: "kg", name: "Mehl"),
        ], to: context)

        let items = try context.fetch(FetchDescriptor<ShoppingItem>())
        #expect(items.count == 2)
    }

    @Test func abgehaktesWirdNichtErgaenzt() throws {
        let context = try makeContext()
        ShoppingListService.add(
            entries: [.init(amount: 200, unit: "g", name: "Mehl")],
            to: context
        )
        let items = try context.fetch(FetchDescriptor<ShoppingItem>())
        items.first?.isChecked = true
        try context.save()

        ShoppingListService.add(
            entries: [.init(amount: 300, unit: "g", name: "Mehl")],
            to: context
        )
        let danach = try context.fetch(FetchDescriptor<ShoppingItem>())
        #expect(danach.count == 2)
    }

    @Test func handEintragWirdZerlegt() throws {
        let context = try makeContext()
        ShoppingListService.addManual(text: "2 Zwiebeln", to: context)

        let items = try context.fetch(FetchDescriptor<ShoppingItem>())
        #expect(items.count == 1)
        #expect(items.first?.amount == 2)
        #expect(items.first?.name == "Zwiebeln")
        #expect(items.first?.isManual == true)
    }

    // MARK: Portionen

    @Test func rezeptMengenWerdenAufPortionenUmgerechnet() throws {
        let context = try makeContext()
        let recipe = Recipe(title: "Pfannkuchen")
        recipe.servings = 4
        recipe.ingredients = [
            Ingredient(amount: 200, unit: "g", name: "Mehl", sortIndex: 0),
            Ingredient(amount: nil, unit: "", name: "Salz", sortIndex: 1),
        ]
        context.insert(recipe)
        try context.save()

        let count = ShoppingListService.add(recipe: recipe, servings: 6, to: context)
        #expect(count == 2)

        let items = try context.fetch(FetchDescriptor<ShoppingItem>())
        #expect(items.first { $0.name == "Mehl" }?.amount == 300)
        // Zutaten ohne Menge bleiben ohne Menge.
        #expect(items.first { $0.name == "Salz" }?.amount == nil)
    }

    @Test func ohnePortionsangabeBleibenDieRezeptmengen() throws {
        let context = try makeContext()
        let recipe = Recipe(title: "Suppe")
        recipe.servings = 4
        recipe.ingredients = [Ingredient(amount: 1, unit: "l", name: "Brühe")]
        context.insert(recipe)
        try context.save()

        ShoppingListService.add(recipe: recipe, to: context)
        ShoppingListService.add(recipe: recipe, servings: 0, to: context)

        let items = try context.fetch(FetchDescriptor<ShoppingItem>())
        #expect(items.count == 1)
        #expect(items.first?.amount == 2)
    }

    @Test func wochenplanRechnetGeplantePortionenUm() throws {
        let context = try makeContext()
        let recipe = Recipe(title: "Gulasch")
        recipe.servings = 2
        recipe.ingredients = [Ingredient(amount: 100, unit: "g", name: "Zwiebeln")]
        context.insert(recipe)

        let today = Calendar.current.startOfDay(for: .now)
        // Einmal für 4 Portionen (×2) und einmal „wie im Rezept“ (×1).
        context.insert(PlannedMeal(date: today, mealType: .dinner, recipe: recipe, servings: 4))
        context.insert(PlannedMeal(date: today, mealType: .lunch, recipe: recipe))
        try context.save()

        let count = ShoppingListService.addCurrentWeek(to: context)
        #expect(count == 2)

        let items = try context.fetch(FetchDescriptor<ShoppingItem>())
        #expect(items.count == 1)
        #expect(items.first?.amount == 300)
    }
}
