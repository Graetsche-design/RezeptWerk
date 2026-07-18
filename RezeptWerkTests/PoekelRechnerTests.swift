import Testing
@testable import RezeptWerk

/// Tests für die Rechenfunktionen des Pökel-Rechners (Nasspökeln).
@MainActor
struct PoekelRechnerTests {

    @Test func achtProzentLakeFuerFuenfLiter() {
        // Konvention: 8 % ≙ 80 g je Liter → 5 l × 80 g = 400 g NPS.
        let gramm = PoekelRechnerView.npsGrams(waterLiters: 5, strengthPercent: 8)
        #expect(abs(gramm - 400) < 0.001)
    }

    @Test func kommaWerteRechnenKorrekt() {
        // 2,5 l bei 6 % → 150 g.
        let gramm = PoekelRechnerView.npsGrams(waterLiters: 2.5, strengthPercent: 6)
        #expect(abs(gramm - 150) < 0.001)
    }

    @Test func zuckerWirdJeLiterGerechnet() {
        #expect(abs(PoekelRechnerView.sugarGrams(waterLiters: 4, gramsPerLiter: 12.5) - 50) < 0.001)
    }

    @Test func poekelzeitNachDicke() {
        // 1 Tag je cm + 2 Sicherheitstage; angebrochene cm zählen voll.
        #expect(PoekelRechnerView.curingDays(thicknessCm: 10) == 12)
        #expect(PoekelRechnerView.curingDays(thicknessCm: 2.5) == 5)
        #expect(PoekelRechnerView.curingDays(thicknessCm: 1) == 3)
    }

    @Test func durchbrennenIstHalbeZeitAufgerundet() {
        #expect(PoekelRechnerView.burnThroughDays(curingDays: 12) == 6)
        #expect(PoekelRechnerView.burnThroughDays(curingDays: 5) == 3)
        #expect(PoekelRechnerView.burnThroughDays(curingDays: 1) == 1)
    }

    @Test func wasserVorschlagVierzigProzent() {
        #expect(abs(PoekelRechnerView.suggestedWaterLiters(meatKg: 5) - 2) < 0.001)
    }
}
