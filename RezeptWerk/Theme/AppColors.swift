import SwiftUI

/// Zentrale Farbpalette von RezeptWerk.
///
/// Alle Farben kommen aus dem Asset-Katalog und besitzen dort jeweils eine
/// Hell- und eine Dunkel-Variante. Dadurch passt sich die App automatisch
/// an den Hell-/Dunkelmodus an, ohne dass irgendwo `colorScheme` abgefragt
/// werden muss.
///
/// Stil: warm, rustikal, handwerklich — Pergament, Holz, Kupfer, Anthrazit.
/// Es gibt bewusst nur EINE Akzentfarbe (Kupfer), damit die Oberfläche
/// ruhig und hochwertig wirkt.
enum AppColors {

    // MARK: Flächen

    /// Grundfläche aller Bildschirme (helles Pergament / dunkles Räucherholz).
    static let backgroundPrimary = Color("BackgroundPrimary")

    /// Karten und angehobene Flächen.
    static let backgroundElevated = Color("BackgroundElevated")

    /// Abgesenkte Flächen: Eingabefelder, Pills, Chips.
    static let backgroundSunken = Color("BackgroundSunken")

    // MARK: Text

    /// Haupttext (Espresso-Braun / warmes Creme).
    static let textPrimary = Color("TextPrimary")

    /// Nebentext, Beschriftungen, Metadaten.
    static let textSecondary = Color("TextSecondary")

    // MARK: Akzente

    /// Die Akzentfarbe der App: Kupfer. Für Buttons, Sterne, aktive Zustände.
    static let copper = Color("AccentCopper")

    /// Warmes Holzbraun für sekundäre Akzente (Icons, Kategorie-Kreise).
    static let wood = Color("WoodBrown")

    /// Feine Trennlinien und Kartenränder.
    /// (Asset heißt „Hairline“, weil „Separator“ mit einem System-Symbol
    /// kollidieren würde.)
    static let separator = Color("Hairline")

    // MARK: Verläufe

    /// Kupfer-Verlauf für primäre Buttons — wirkt wie gebürstetes Metall.
    static var copperGradient: LinearGradient {
        LinearGradient(
            colors: [copper, copper.opacity(0.82)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Warmer Platzhalter-Verlauf für Rezepte ohne Foto.
    static var placeholderGradient: LinearGradient {
        LinearGradient(
            colors: [wood.opacity(0.35), wood.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Dezenter Schatten für Karten (warmer Braunton statt hartem Grau).
    static var cardShadow: Color {
        Color(red: 0.18, green: 0.11, blue: 0.05).opacity(0.10)
    }
}
