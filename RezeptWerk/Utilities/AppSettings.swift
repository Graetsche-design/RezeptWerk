import SwiftUI

/// Schlüssel und Wertetypen für alle App-Einstellungen (`@AppStorage`).
///
/// Die Einstellungen werden in den `UserDefaults` gespeichert — also lokal
/// auf dem Gerät, genau wie alle anderen Daten der App.
enum SettingsKeys {
    /// Erscheinungsbild: System / Hell / Dunkel.
    static let appearance = "settings.appearance"
    /// Schriftgröße im Kochmodus.
    static let cookingFontSize = "settings.cookingFontSize"
    /// iCloud-Synchronisierung an/aus (Standard: aus).
    static let iCloudSync = "settings.icloudSync"
    /// Bildschirm immer anlassen, solange die App geöffnet ist
    /// (Standard: aus). Der Kochmodus hält den Bildschirm immer wach —
    /// unabhängig von dieser Einstellung.
    static let keepScreenOn = "settings.keepScreenOn"
    /// Kochmodus: jeden neuen Schritt beim Blättern automatisch vorlesen
    /// (Standard: aus).
    static let cookingAutoRead = "settings.cookingAutoRead"
    /// Gemerkte Portionszahl beim Einplanen im Wochenplan
    /// (0 = wie im Rezept).
    static let plannerServings = "planner.servings"
    /// Gemerkte Zutatenliste des Wurst-Rechners (JSON).
    static let sausageCalculatorRows = "tools.sausageCalculator.rows"
    /// Gemerkte Fleischliste des Wurst-Rechners (JSON).
    static let sausageCalculatorMeats = "tools.sausageCalculator.meats"

    // Gemerkte Eingaben des Pökel-Rechners (als Text, deutsche Kommas).
    static let brineMeatKg = "tools.brineCalculator.meatKg"
    static let brineWaterLiters = "tools.brineCalculator.waterLiters"
    static let brineStrengthPercent = "tools.brineCalculator.strengthPercent"
    static let brineSugarPerLiter = "tools.brineCalculator.sugarPerLiter"
    static let brineThicknessCm = "tools.brineCalculator.thicknessCm"
}

/// Erscheinungsbild der App.
enum AppearanceSetting: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: "Automatisch"
        case .light: "Hell"
        case .dark: "Dunkel"
        }
    }

    /// `nil` bedeutet: dem System folgen.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

/// Schriftgröße im Kochmodus — bewusst nur drei klare Stufen.
enum CookingFontSize: String, CaseIterable, Identifiable {
    case normal
    case large
    case extraLarge

    var id: String { rawValue }

    var label: String {
        switch self {
        case .normal: "Normal"
        case .large: "Groß"
        case .extraLarge: "Sehr groß"
        }
    }

    /// Skalierungsfaktor für die Kochmodus-Schriften (siehe `AppTypography`).
    var scale: Double {
        switch self {
        case .normal: 1.0
        case .large: 1.2
        case .extraLarge: 1.45
        }
    }
}
