import Foundation

/// Ein Eintrag im Kerntemperatur-Spickzettel.
struct TemperatureEntry: Identifiable {
    let id = UUID()
    /// Was gegart wird, inkl. Garstufe — z. B. „Steak · medium“.
    let name: String
    /// Der Temperaturbereich als Text — bewusst ein String, damit auch
    /// „ab 74“, „unter 25“ oder „88–95“ möglich sind.
    let range: String
    /// Optionaler Zusatzhinweis (z. B. Sicherheit oder Ruhezeit).
    let note: String?

    init(_ name: String, _ range: String, note: String? = nil) {
        self.name = name
        self.range = range
        self.note = note
    }
}

/// Eine Gruppe des Spickzettels (Rind, Schwein, Geflügel …).
struct TemperatureGroup: Identifiable {
    let id = UUID()
    let title: String
    /// SF-Symbol für die Abschnitts-Überschrift.
    let icon: String
    let entries: [TemperatureEntry]
}

/// Die Inhalte des Kerntemperatur-Spickzettels.
///
/// Alle Werte sind bewährte **Richtwerte** in °C (Kerntemperatur, sofern
/// nicht anders angegeben). Änderungen: einfach hier eintragen — die
/// Ansicht (`KerntemperaturView`) übernimmt sie automatisch.
enum KerntemperaturData {

    static let groups: [TemperatureGroup] = [

        TemperatureGroup(title: "Rind", icon: "flame", entries: [
            TemperatureEntry("Steak / Filet · rare", "48–52 °C"),
            TemperatureEntry("Steak / Filet · medium rare", "53–56 °C"),
            TemperatureEntry("Steak / Filet · medium", "57–59 °C"),
            TemperatureEntry("Steak / Filet · durch", "ab 60 °C"),
            TemperatureEntry("Roastbeef · rosa", "53–56 °C",
                             note: "Nach dem Garen 10 Min. ruhen lassen."),
            TemperatureEntry("Burger / Hackfleisch", "ab 70 °C",
                             note: "Hackfleisch immer sicher durchgaren."),
        ]),

        TemperatureGroup(title: "Schwein", icon: "frying.pan", entries: [
            TemperatureEntry("Filet · rosa", "58–62 °C"),
            TemperatureEntry("Braten · durch", "68–72 °C"),
            TemperatureEntry("Pulled Pork", "88–95 °C",
                             note: "Erst bei dieser Temperatur zerfällt das Fleisch."),
            TemperatureEntry("Spareribs", "86–92 °C"),
            TemperatureEntry("Kochschinken", "64–68 °C"),
            TemperatureEntry("Kasseler", "62–65 °C"),
        ]),

        TemperatureGroup(title: "Geflügel", icon: "bird", entries: [
            TemperatureEntry("Hähnchenbrust", "ab 74 °C",
                             note: "Geflügel immer durchgaren."),
            TemperatureEntry("Hähnchenkeule", "80–85 °C"),
            TemperatureEntry("Pute", "ab 75 °C"),
            TemperatureEntry("Entenbrust · rosa", "58–62 °C",
                             note: "Auf Nummer sicher: ab 70 °C durchgaren."),
            TemperatureEntry("Gans", "75–80 °C"),
        ]),

        TemperatureGroup(title: "Lamm & Wild", icon: "pawprint", entries: [
            TemperatureEntry("Lammrücken · rosa", "55–58 °C"),
            TemperatureEntry("Lamm · durch", "ab 62 °C"),
            TemperatureEntry("Reh- / Hirschrücken · rosa", "55–58 °C"),
            TemperatureEntry("Wildschwein", "ab 72 °C",
                             note: "Immer durchgaren (Trichinen-Gefahr)."),
        ]),

        TemperatureGroup(title: "Fisch", icon: "fish", entries: [
            TemperatureEntry("Lachs · glasig", "52–55 °C"),
            TemperatureEntry("Lachs · durch", "58–60 °C"),
            TemperatureEntry("Forelle", "58–62 °C"),
            TemperatureEntry("Thunfisch-Steak · rare", "45–50 °C",
                             note: "Nur bei bester, frischer Qualität."),
        ]),

        TemperatureGroup(title: "Wurst & Räuchern", icon: "smoke", entries: [
            TemperatureEntry("Brühwurst · Kern", "70–72 °C",
                             note: "Brühen bei 76–80 °C Wassertemperatur."),
            TemperatureEntry("Leberkäse", "72 °C"),
            TemperatureEntry("Forelle · heißgeräuchert", "60–63 °C"),
            TemperatureEntry("Kalträuchern · Kammer", "unter 25 °C",
                             note: "Kammer-, nicht Kerntemperatur."),
            TemperatureEntry("Warmräuchern · Kammer", "30–50 °C",
                             note: "Kammer-, nicht Kerntemperatur."),
            TemperatureEntry("Heißräuchern · Kammer", "60–90 °C",
                             note: "Kammer-, nicht Kerntemperatur."),
        ]),
    ]
}
