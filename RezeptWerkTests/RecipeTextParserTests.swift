import Testing
@testable import RezeptWerk

/// Tests für den Text-Parser — das Herz des Imports (Foto/PDF/Text).
struct RecipeTextParserTests {

    // MARK: Zutatenzeilen

    @Test func mengeEinheitNameWerdenZerlegt() {
        let parsed = RecipeTextParser.parseIngredientLine("250 g Mehl")
        #expect(parsed.amount == 250)
        #expect(parsed.unit == "g")
        #expect(parsed.name == "Mehl")
    }

    @Test func kommaMengeMitKilogramm() {
        let parsed = RecipeTextParser.parseIngredientLine("1,5 kg Rinderbrust")
        #expect(parsed.amount == 1.5)
        #expect(parsed.unit == "kg")
        #expect(parsed.name == "Rinderbrust")
    }

    @Test func stueckzahlOhneEinheit() {
        let parsed = RecipeTextParser.parseIngredientLine("2 Eier")
        #expect(parsed.amount == 2)
        #expect(parsed.unit.isEmpty)
        #expect(parsed.name == "Eier")
    }

    @Test func zutatOhneMenge() {
        let parsed = RecipeTextParser.parseIngredientLine("Salz")
        #expect(parsed.amount == nil)
        #expect(parsed.name == "Salz")
    }

    @Test func aufzaehlungszeichenWerdenEntfernt() {
        let parsed = RecipeTextParser.parseIngredientLine("- 100 g Zucker")
        #expect(parsed.amount == 100)
        #expect(parsed.unit == "g")
        #expect(parsed.name == "Zucker")
    }

    // MARK: Kompletter Text

    @Test func rezeptMitUeberschriftenWirdZerlegt() {
        let text = """
        Pfannkuchen

        Zutaten:
        250 g Mehl
        2 Eier

        Zubereitung:
        1. Alles zu einem glatten Teig verrühren.

        2. In der heißen Pfanne goldbraun ausbacken.
        """

        let parsed = RecipeTextParser.parse(text)
        #expect(parsed.title == "Pfannkuchen")
        #expect(parsed.ingredients.count == 2)
        #expect(parsed.ingredients.first?.amount == 250)
        #expect(parsed.steps.count == 2)
        #expect(parsed.steps.first == "Alles zu einem glatten Teig verrühren.")
    }
}
