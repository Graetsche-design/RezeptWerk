import Testing
import Foundation
@testable import RezeptWerk

/// Tests für die Portionsumrechnung, die Portionsrechner, Kochmodus und
/// Einkaufsliste gemeinsam nutzen.
@MainActor
struct ServingsScalingTests {

    @Test func faktorAusPortionen() {
        let recipe = Recipe(title: "Test")
        recipe.servings = 4

        #expect(recipe.scaleFactor(forServings: 6) == 1.5)
        #expect(recipe.scaleFactor(forServings: 2) == 0.5)
        // Nichts umrechnen bei: gleicher Zahl, keiner Angabe, Unsinn.
        #expect(recipe.scaleFactor(forServings: 4) == 1)
        #expect(recipe.scaleFactor(forServings: nil) == 1)
        #expect(recipe.scaleFactor(forServings: 0) == 1)
    }

    @Test func rezeptOhnePortionenRechnetNichtUm() {
        let recipe = Recipe(title: "Test")
        recipe.servings = 0
        #expect(recipe.scaleFactor(forServings: 3) == 1)
    }

    @Test func planeintragOhneAngabeNimmtRezeptportionen() {
        let recipe = Recipe(title: "Test")
        recipe.servings = 3
        let meal = PlannedMeal(date: .now, mealType: .dinner, recipe: recipe)

        #expect(meal.servings == 0)
        #expect(meal.effectiveServings == 3)
        #expect(meal.scaleFactor == 1)

        meal.servings = 6
        #expect(meal.effectiveServings == 6)
        #expect(meal.scaleFactor == 2)
    }

    @Test func planeintragOhneRezeptBleibtHarmlos() {
        let meal = PlannedMeal(date: .now, mealType: .lunch, recipe: nil)
        #expect(meal.effectiveServings == 1)
        #expect(meal.scaleFactor == 1)
    }

    @Test func kochmodusRechnetZutatenUm() {
        let recipe = Recipe(title: "Test")
        recipe.servings = 2
        recipe.ingredients = [Ingredient(amount: 250, unit: "g", name: "Hack")]

        let vm = CookingModeViewModel(recipe: recipe, servings: 5)
        #expect(vm.servings == 5)
        #expect(vm.isScaled)
        #expect(vm.scaleFactor == 2.5)
        #expect(recipe.sortedIngredients.first?.displayText(scaledBy: vm.scaleFactor) == "625 g Hack")

        let standard = CookingModeViewModel(recipe: recipe)
        #expect(standard.servings == 2)
        #expect(!standard.isScaled)
        #expect(standard.scaleFactor == 1)

        // 0 bedeutet ebenfalls „wie im Rezept“.
        #expect(CookingModeViewModel(recipe: recipe, servings: 0).servings == 2)
    }
}
