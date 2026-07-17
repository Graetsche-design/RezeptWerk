import Testing
import SwiftData
@testable import RezeptWerk

/// Tests fürs Zusammenfassen der Einkaufsliste.
@MainActor
struct ShoppingListServiceTests {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: ModelContainerFactory.schema,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
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
}
