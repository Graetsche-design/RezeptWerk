import Testing
@testable import RezeptWerk

/// Tests für die Zahl- und Zeitformatierung — das Fundament von
/// Portionsrechner, Wurst-Rechner und Einkaufsliste.
struct FormatHelpersTests {

    // MARK: Mengen einlesen

    @Test func kommaZahlWirdGelesen() {
        #expect(FormatHelpers.parseAmount("2,5") == 2.5)
    }

    @Test func punktZahlWirdGelesen() {
        #expect(FormatHelpers.parseAmount("1.5") == 1.5)
    }

    @Test func leerzeichenWerdenIgnoriert() {
        #expect(FormatHelpers.parseAmount("  3 ") == 3)
    }

    @Test func unsinnErgibtNil() {
        #expect(FormatHelpers.parseAmount("abc") == nil)
        #expect(FormatHelpers.parseAmount("") == nil)
    }

    // MARK: Mengen ausgeben

    @Test func ganzeZahlOhneNachkommastellen() {
        #expect(FormatHelpers.amountText(2.0) == "2")
    }

    @Test func kommaZahlMitDeutschemKomma() {
        #expect(FormatHelpers.amountText(1.5) == "1,5")
    }

    @Test func nullUndNilErgebenNil() {
        #expect(FormatHelpers.amountText(nil) == nil)
        #expect(FormatHelpers.amountText(0) == nil)
    }

    @Test func einleseAusgabeRoundtrip() {
        let text = FormatHelpers.amountText(2.5)
        #expect(text != nil)
        #expect(FormatHelpers.parseAmount(text ?? "") == 2.5)
    }

    // MARK: Zeiten

    @Test func minutenTextMitStunden() {
        #expect(FormatHelpers.minutesText(80) == "1 Std. 20 Min.")
        #expect(FormatHelpers.minutesText(45) == "45 Min.")
        #expect(FormatHelpers.minutesText(120) == "2 Std.")
    }

    @Test func timerAnzeige() {
        #expect(FormatHelpers.timerText(seconds: 90) == "01:30")
        #expect(FormatHelpers.timerText(seconds: 3661) == "1:01:01")
        #expect(FormatHelpers.timerText(seconds: -5) == "00:00")
    }
}
