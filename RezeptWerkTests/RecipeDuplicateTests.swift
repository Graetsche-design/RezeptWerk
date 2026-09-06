import Testing
import SwiftData
import Foundation
@testable import RezeptWerk

/// Tests fürs Duplizieren eines Rezepts („Variante anlegen“).
@MainActor
struct RecipeDuplicateTests {

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

    private func makeOriginal(in context: ModelContext) throws -> Recipe {
        let original = Recipe(title: "Käsekrakauer")
        original.servings = 10
        original.rating = 5
        original.isFavorite = true
        original.notes = "Mit Gouda"
        original.ingredients = [
            Ingredient(amount: 1, unit: "kg", name: "Schweineschulter", sortIndex: 0),
            Ingredient(amount: 200, unit: "g", name: "Käse", sortIndex: 1),
        ]
        original.steps = [
            RecipeStep(text: "Wolfen", sortIndex: 0),
            RecipeStep(text: "Füllen", sortIndex: 1, timerSeconds: 600),
        ]
        original.images = [RecipeImage(data: Data([1, 2, 3]), sortIndex: 0)]
        original.tags = [RecipeTag(name: "Brühwurst")]
        context.insert(original)
        try context.save()
        return original
    }

    @Test func kopieUebernimmtInhaltAberNichtBewertungUndFavorit() throws {
        let context = try makeContext()
        let original = try makeOriginal(in: context)

        let draft = RecipeDraft(duplicating: original)

        #expect(draft.title == "Käsekrakauer (Kopie)")
        #expect(draft.rating == 0)
        #expect(draft.isFavorite == false)
        #expect(draft.servings == 10)
        #expect(draft.notes == "Mit Gouda")
        #expect(draft.ingredients.count == 2)
        #expect(draft.steps.count == 2)
        #expect(draft.steps.last?.timerMinutesText == "10")
        #expect(draft.imageDatas.count == 1)
        #expect(draft.tagNames == ["Brühwurst"])
        #expect(draft.canSave)
    }

    @Test func gespeicherteKopieIstEigenesRezeptUndOriginalBleibt() throws {
        let context = try makeContext()
        let original = try makeOriginal(in: context)

        let copy = try RecipeImportService.save(
            draft: RecipeDraft(duplicating: original),
            updating: nil,
            in: context
        )

        let alleRezepte = try context.fetch(FetchDescriptor<Recipe>())
        #expect(alleRezepte.count == 2)
        #expect(copy.persistentModelID != original.persistentModelID)
        #expect(copy.title == "Käsekrakauer (Kopie)")
        #expect(copy.sortedIngredients.count == 2)
        #expect(copy.sortedIngredients.first?.name == "Schweineschulter")
        #expect(copy.sortedSteps.last?.timerSeconds == 600)
        #expect(copy.sortedImages.first?.data == Data([1, 2, 3]))
        #expect(copy.rating == 0)
        #expect(copy.isFavorite == false)

        // Der Tag wird wiederverwendet statt verdoppelt.
        let alleTags = try context.fetch(FetchDescriptor<RecipeTag>())
        #expect(alleTags.count == 1)
        #expect(copy.tagNames == ["Brühwurst"])

        // Das Original ist unberührt.
        #expect(original.title == "Käsekrakauer")
        #expect(original.rating == 5)
        #expect(original.isFavorite)
        #expect(original.sortedIngredients.count == 2)
        #expect(original.sortedImages.count == 1)
    }
}
