import Testing
@testable import RezeptWerk

/// Tests für die Rechenfunktionen des Maß-Umrechners.
struct UmrechnerTests {

    @Test func cupMehlErgibtRundHundertfuenfundzwanzigGramm() {
        let mehl = UmrechnerData.ingredients.first { $0.name == "Weizenmehl" }!
        let gramm = UmrechnerData.grams(amount: 1, unit: .cup, ingredient: mehl)
        // 236,59 ml × 0,53 g/ml ≈ 125 g (üblicher Küchen-Richtwert).
        #expect(abs(gramm - 125.4) < 1)
    }

    @Test func essloeffelWasserSindFuenfzehnGramm() {
        let wasser = UmrechnerData.ingredients.first { $0.name == "Wasser" }!
        let gramm = UmrechnerData.grams(amount: 1, unit: .tablespoon, ingredient: wasser)
        #expect(abs(gramm - 15) < 0.001)
    }

    @Test func unzenUndPfundInGramm() {
        #expect(abs(UmrechnerData.grams(fromOunces: 1) - 28.3495) < 0.001)
        #expect(abs(UmrechnerData.grams(fromPounds: 1) - 453.592) < 0.001)
        #expect(abs(UmrechnerData.grams(fromOunces: 16) - UmrechnerData.grams(fromPounds: 1)) < 0.01)
    }

    @Test func fluessigeUnzeWasserErgibtRundDreissigGramm() {
        let wasser = UmrechnerData.ingredients.first { $0.name == "Wasser" }!
        let gramm = UmrechnerData.grams(amount: 1, unit: .fluidOunce, ingredient: wasser)
        // 1 fl oz = 29,5735 ml; Wasser mit Dichte 1 → ebenso viele Gramm.
        #expect(abs(gramm - 29.5735) < 0.001)
        // 8 fl oz sind genau ein US-Cup (Rundungstoleranz der Cup-Konstante).
        let cup = UmrechnerData.grams(amount: 1, unit: .cup, ingredient: wasser)
        #expect(abs(UmrechnerData.grams(amount: 8, unit: .fluidOunce, ingredient: wasser) - cup) < 0.1)
    }

    @Test func fahrenheitCelsiusRoundtrip() {
        #expect(abs(UmrechnerData.celsius(fromFahrenheit: 212) - 100) < 0.001)
        #expect(abs(UmrechnerData.celsius(fromFahrenheit: 32) - 0) < 0.001)
        #expect(abs(UmrechnerData.fahrenheit(fromCelsius: 180) - 356) < 0.001)
        // Hin und zurück landet beim Ausgangswert.
        let roundtrip = UmrechnerData.celsius(fromFahrenheit: UmrechnerData.fahrenheit(fromCelsius: 42))
        #expect(abs(roundtrip - 42) < 0.001)
    }

    @Test func kommaEingabeWirdGeparst() {
        // „1,5“ Cups Zucker: 1,5 × 236,59 × 0,85 ≈ 301,7 g.
        let zucker = UmrechnerData.ingredients.first { $0.name == "Zucker (weiß)" }!
        let menge = FormatHelpers.parseAmount("1,5")
        #expect(menge == 1.5)
        let gramm = UmrechnerData.grams(amount: menge ?? 0, unit: .cup, ingredient: zucker)
        #expect(abs(gramm - 301.65) < 1)
    }
}
