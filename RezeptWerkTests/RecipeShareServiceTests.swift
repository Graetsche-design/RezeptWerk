import Testing
import SwiftData
import Foundation
@testable import RezeptWerk

/// Tests für den Rezept-Tausch als `.rezeptwerk`-Datei.
@MainActor
struct RecipeShareServiceTests {

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

    /// Baut ein Rezept mit persönlichen Spuren, teilt es als Datei und
    /// prüft: Rezeptdaten kommen an, Persönliches nicht.
    @Test func dateiRoundtripStripptPersoenliches() throws {
        let context = try makeContext()

        let recipe = Recipe(title: "Tausch-Gulasch")
        recipe.rating = 5
        recipe.isFavorite = true
        recipe.lastCookedAt = .now
        recipe.ingredients = [Ingredient(amount: 500, unit: "g", name: "Rindfleisch")]
        recipe.steps = [RecipeStep(text: "Schmoren", sortIndex: 0, timerSeconds: 5400)]
        let note = CookingNote(text: "Privates Geheimnis")
        note.recipe = recipe
        context.insert(recipe)
        context.insert(note)
        try context.save()

        let url = try RecipeShareService.makeShareFile(for: recipe)
        #expect(url.pathExtension == "rezeptwerk")
        #expect(FileManager.default.fileExists(atPath: url.path))

        let geladen = try RecipeShareService.loadRecipe(from: url)
        #expect(geladen.title == "Tausch-Gulasch")
        #expect(geladen.ingredients.first?.amount == 500)
        #expect(geladen.steps.first?.timerSeconds == 5400)
        // Persönliches wurde entfernt:
        #expect(geladen.rating == 0)
        #expect(geladen.isFavorite == false)
        #expect(geladen.lastCookedAt == nil)
        #expect(geladen.cookingNotes == nil)
    }

    /// Aus der geladenen Datei entsteht ein vollständiger Editor-Entwurf.
    @Test func geladeneDateiWirdZumDraft() throws {
        let context = try makeContext()

        let recipe = Recipe(title: "Draft-Test")
        recipe.ingredients = [Ingredient(amount: 2, unit: "", name: "Eier")]
        recipe.steps = [RecipeStep(text: "Verquirlen", sortIndex: 0)]
        context.insert(recipe)
        try context.save()

        let url = try RecipeShareService.makeShareFile(for: recipe)
        let backup = try RecipeShareService.loadRecipe(from: url)
        let draft = RecipeDraft(backup: backup, context: context)

        #expect(draft.title == "Draft-Test")
        #expect(draft.ingredients.count == 1)
        #expect(draft.ingredients.first?.name == "Eier")
        #expect(draft.steps.first?.text == "Verquirlen")
        #expect(draft.canSave)
    }

    /// Unsinnige Dateien führen zu einem Fehler statt zu einem Absturz.
    @Test func kaputteDateiWirftFehler() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("kaputt.rezeptwerk")
        try Data("kein json".utf8).write(to: url)

        #expect(throws: RecipeShareService.ShareError.self) {
            _ = try RecipeShareService.loadRecipe(from: url)
        }
    }
}
