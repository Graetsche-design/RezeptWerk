import Testing
@testable import RezeptWerk

/// Tests für die Rechenlogik des Wurst-Rechners („Als Rezept speichern“).
@MainActor
struct WurstRechnerTests {

    private func beispielDraft() -> RecipeDraft {
        WurstRechnerView.makeDraft(
            title: "Test-Bratwurst",
            meats: [
                MeatRow(name: "Schweineschulter", kilogramsText: "1,5"),
                MeatRow(name: "Rinderbrust", kilogramsText: "1"),
            ],
            rows: [
                CalculatorRow(name: "Nitritpökelsalz (NPS)", gramsPerKgText: "18"),
                CalculatorRow(name: "Pfeffer, gemahlen", gramsPerKgText: "2,5"),
            ],
            categories: []
        )
    }

    @Test func grunddatenStimmen() {
        let draft = beispielDraft()
        #expect(draft.title == "Test-Bratwurst")
        #expect(draft.servings == 1)
        #expect(draft.includeSausageDetails)
        #expect(draft.category == nil) // keine Kategorien übergeben
    }

    @Test func fleischMixLandetInZutaten() {
        let draft = beispielDraft()
        // 2 Fleischsorten + 2 berechnete Zutaten
        #expect(draft.ingredients.count == 4)
        #expect(draft.ingredients[0].name == "Schweineschulter")
        #expect(draft.ingredients[0].amountText == "1,5")
        #expect(draft.ingredients[0].unit == "kg")
    }

    @Test func mengenWerdenAufGesamtgewichtHochgerechnet() {
        let draft = beispielDraft()
        // 2,5 kg × 18 g/kg = 45 g NPS · 2,5 × 2,5 = 6,25 g Pfeffer
        let nps = draft.ingredients.first { $0.name.contains("Nitritpökelsalz") }
        #expect(nps?.amountText == "45")
        #expect(nps?.unit == "g")

        let pfeffer = draft.ingredients.first { $0.name.contains("Pfeffer") }
        #expect(pfeffer?.amountText == "6,25")
    }

    @Test func fachdatenWerdenBefuellt() {
        let draft = beispielDraft()
        #expect(draft.meatWeightText == "2,5")
        #expect(draft.npsText == "18")
        #expect(draft.seasoningPerKg == "2,5 g Pfeffer, gemahlen")
    }

    @Test func leereZeilenWerdenUebersprungen() {
        let draft = WurstRechnerView.makeDraft(
            title: "Leer-Test",
            meats: [MeatRow(name: "", kilogramsText: "")],
            rows: [CalculatorRow(name: "", gramsPerKgText: "5")],
            categories: []
        )
        // Keine gültige Fleisch-Zeile, keine benannte Zutat →
        // der Draft behält seine Standard-Leerzeile.
        let alleLeer = draft.ingredients.allSatisfy { $0.isEmpty }
        #expect(alleLeer)
    }
}
