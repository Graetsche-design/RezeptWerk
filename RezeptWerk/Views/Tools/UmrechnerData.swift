import Foundation

/// Eine Zutat mit ihrer Dichte für die Volumen-zu-Gewicht-Umrechnung.
struct ConversionIngredient: Identifiable {
    /// Der Name dient als stabile Kennung (jede Zutat kommt nur einmal vor).
    var id: String { name }
    let name: String
    /// Dichte in Gramm je Milliliter — übliche Küchen-Richtwerte für lose
    /// Schüttung (1 Cup Mehl ≈ 125 g, 1 Cup Zucker ≈ 200 g …).
    let gramsPerMilliliter: Double
}

/// Volumen-Einheiten, die in (amerikanischen) Rezepten vorkommen.
enum VolumeUnit: String, CaseIterable, Identifiable {
    case cup
    case tablespoon
    case teaspoon
    case milliliter

    var id: String { rawValue }

    var label: String {
        switch self {
        case .cup: "Cup (US)"
        case .tablespoon: "EL"
        case .teaspoon: "TL"
        case .milliliter: "ml"
        }
    }

    /// Milliliter je Einheit (US-Cup; EL/TL nach deutscher Konvention).
    var milliliters: Double {
        switch self {
        case .cup: 236.59
        case .tablespoon: 15
        case .teaspoon: 5
        case .milliliter: 1
        }
    }
}

/// Daten und Rechenfunktionen des Maß-Umrechners.
///
/// Alle Werte sind bewährte Küchen-Richtwerte — hier zentral gepflegt und
/// leicht erweiterbar (gleiches Prinzip wie `KerntemperaturData`).
enum UmrechnerData {

    // MARK: Zutaten-Dichten (Volumen → Gewicht)

    static let ingredients: [ConversionIngredient] = [
        ConversionIngredient(name: "Wasser", gramsPerMilliliter: 1.0),
        ConversionIngredient(name: "Milch", gramsPerMilliliter: 1.03),
        ConversionIngredient(name: "Sahne", gramsPerMilliliter: 1.01),
        ConversionIngredient(name: "Öl", gramsPerMilliliter: 0.92),
        ConversionIngredient(name: "Butter (weich)", gramsPerMilliliter: 0.96),
        ConversionIngredient(name: "Honig / Sirup", gramsPerMilliliter: 1.42),
        ConversionIngredient(name: "Weizenmehl", gramsPerMilliliter: 0.53),
        ConversionIngredient(name: "Zucker (weiß)", gramsPerMilliliter: 0.85),
        ConversionIngredient(name: "Zucker (braun, gedrückt)", gramsPerMilliliter: 0.93),
        ConversionIngredient(name: "Puderzucker", gramsPerMilliliter: 0.56),
        ConversionIngredient(name: "Salz (fein)", gramsPerMilliliter: 1.2),
        ConversionIngredient(name: "Reis (roh)", gramsPerMilliliter: 0.85),
        ConversionIngredient(name: "Haferflocken", gramsPerMilliliter: 0.41),
        ConversionIngredient(name: "Kakaopulver", gramsPerMilliliter: 0.53),
        ConversionIngredient(name: "Speisestärke", gramsPerMilliliter: 0.64),
        ConversionIngredient(name: "Paniermehl", gramsPerMilliliter: 0.48),
    ]

    /// Volumen-Angabe einer Zutat in Gramm.
    static func grams(amount: Double, unit: VolumeUnit, ingredient: ConversionIngredient) -> Double {
        amount * unit.milliliters * ingredient.gramsPerMilliliter
    }

    // MARK: Gewicht

    /// 1 Unze (oz) = 28,3495 g.
    static func grams(fromOunces ounces: Double) -> Double {
        ounces * 28.3495
    }

    /// 1 Pfund (lb) = 453,592 g.
    static func grams(fromPounds pounds: Double) -> Double {
        pounds * 453.592
    }

    // MARK: Temperatur

    static func celsius(fromFahrenheit fahrenheit: Double) -> Double {
        (fahrenheit - 32) * 5 / 9
    }

    static func fahrenheit(fromCelsius celsius: Double) -> Double {
        celsius * 9 / 5 + 32
    }

    /// Gasherd-Stufen als grobe Orientierung (übliche Richtwerte für
    /// deutsche Gasherde mit den Stufen 1–8).
    static let gasMarks: [(stufe: String, celsius: String)] = [
        ("Stufe 1", "ca. 150 °C"),
        ("Stufe 2", "ca. 160 °C"),
        ("Stufe 3", "ca. 180 °C"),
        ("Stufe 4", "ca. 200 °C"),
        ("Stufe 5", "ca. 220 °C"),
        ("Stufe 6", "ca. 240 °C"),
        ("Stufe 7", "ca. 260 °C"),
        ("Stufe 8", "ca. 280 °C"),
    ]
}
