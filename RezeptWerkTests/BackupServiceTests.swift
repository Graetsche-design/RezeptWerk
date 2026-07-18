import Testing
import SwiftData
import Foundation
@testable import RezeptWerk

/// Tests für Backup & Wiederherstellen — komplett in einer
/// Wegwerf-Datenbank im Arbeitsspeicher.
@MainActor
struct BackupServiceTests {

    /// Hält die Wegwerf-Container bis zum Prozessende am Leben:
    /// `mainContext` referenziert seinen Container nicht stark — ohne
    /// diesen Anker würde er am Funktionsende freigegeben und schon das
    /// nächste `insert` stürzt in SwiftData ab (Verhalten seit OS 26.5).
    private static var lebendeContainer: [ModelContainer] = []

    /// Frischer In-Memory-Container mit dem echten App-Schema.
    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: ModelContainerFactory.schema,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        Self.lebendeContainer.append(container)
        return container.mainContext
    }

    @Test func roundtripErhaeltRezeptdaten() throws {
        let context = try makeContext()

        let recipe = Recipe(title: "Roundtrip-Wurst")
        recipe.ingredients = [Ingredient(amount: 250, unit: "g", name: "Mehl")]
        recipe.steps = [RecipeStep(
            text: "Rühren",
            sortIndex: 0,
            timerSeconds: 90,
            imageData: Data("SCHRITTBILD".utf8)
        )]
        let note = CookingNote(text: "Sehr gut!")
        note.recipe = recipe
        context.insert(recipe)
        context.insert(note)
        try context.save()

        let data = try BackupService.makeBackupData(context: context)
        let restored = try BackupService.restore(from: data, mode: .merge, context: context)
        #expect(restored == 1)

        let all = try context.fetch(FetchDescriptor<Recipe>())
        #expect(all.count == 2)
        let kopie = all.first { $0.sortedCookingNotes.isEmpty == false && $0 !== recipe }
        #expect(kopie?.sortedIngredients.first?.amount == 250)
        #expect(kopie?.sortedSteps.first?.timerSeconds == 90)
        #expect(kopie?.sortedSteps.first?.imageData == Data("SCHRITTBILD".utf8))
        #expect(kopie?.sortedCookingNotes.first?.text == "Sehr gut!")
    }

    /// Regression: Zwei gleichnamige Kategorien (iCloud-Duplikate) dürfen
    /// die Wiederherstellung nicht mehr abstürzen lassen.
    @Test func doppelteKategorienStuerzenNichtAb() throws {
        let context = try makeContext()

        context.insert(RecipeCategory(name: "Duplikat"))
        context.insert(RecipeCategory(name: "Duplikat"))
        context.insert(Recipe(title: "Absturz-Test"))
        try context.save()

        let data = try BackupService.makeBackupData(context: context)
        let restored = try BackupService.restore(from: data, mode: .merge, context: context)
        #expect(restored == 1)
    }

    /// Alte Backups (Version 1.4, ohne die neueren optionalen Felder)
    /// müssen lesbar bleiben.
    @Test func altesBackupFormatBleibtLesbar() throws {
        let context = try makeContext()

        let altesJSON = """
        {"formatVersion":1,"appVersion":"1.4","exportedAt":"2026-07-01T10:00:00Z",
         "recipes":[{"title":"Alt-Rezept","servings":2,"difficultyRaw":1,"rating":0,
         "isFavorite":false,"notes":"","sourceText":"","sourceURLString":"",
         "createdAt":"2026-07-01T10:00:00Z","updatedAt":"2026-07-01T10:00:00Z",
         "tags":[],"ingredients":[],"steps":[],"imagesBase64":[]}]}
        """

        let restored = try BackupService.restore(
            from: Data(altesJSON.utf8),
            mode: .merge,
            context: context
        )
        #expect(restored == 1)
    }
}
