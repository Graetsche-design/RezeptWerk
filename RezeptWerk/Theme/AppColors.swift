import SwiftUI

/// Zentrale Farbpalette von RezeptWerk — Design „Dunkle Glut“.
///
/// Die App ist bewusst immer dunkel: Anthrazit wie Räucherholz als Grund,
/// dunkle Karten mit feiner Kontur, cremefarbener Text — und darauf ein
/// glühendes Kupfer als Akzent, das an die Glut im Smoker erinnert.
///
/// Alle Grundfarben liegen im Asset-Katalog; Hell- und Dunkel-Eintrag sind
/// dort identisch, damit auch System-Elemente nie hell aufblitzen. Den
/// Dunkelmodus erzwingt `RootView` zusätzlich (`preferredColorScheme`).
enum AppColors {

    // MARK: Flächen

    /// Grundfläche aller Bildschirme — dunkles Räucherholz (#1B1713).
    static let backgroundPrimary = Color("BackgroundPrimary")

    /// Karten und angehobene Flächen (#272220).
    static let backgroundElevated = Color("BackgroundElevated")

    /// Abgesenkte Flächen: Eingabefelder, Pills, Chips (#15120E).
    static let backgroundSunken = Color("BackgroundSunken")

    // MARK: Text

    /// Haupttext — warmes Creme (#F0E8D9).
    static let textPrimary = Color("TextPrimary")

    /// Nebentext, Beschriftungen, Metadaten (#A99B85).
    static let textSecondary = Color("TextSecondary")

    // MARK: Akzente

    /// Die Akzentfarbe der App: glühendes Kupfer (#D9803D). Für Buttons,
    /// Sterne, aktive Zustände, Symbolkreise.
    static let copper = Color("AccentCopper")

    /// Warmes Holzbraun für sekundäre Akzente (Platzhalter-Verläufe).
    static let wood = Color("WoodBrown")

    /// Feine Trennlinien und Kartenränder (#393129).
    /// (Asset heißt „Hairline“, weil „Separator“ mit einem System-Symbol
    /// kollidieren würde.)
    static let separator = Color("Hairline")

    /// Glut-Rot — das heiße Ende der Akzent-Verläufe (#F25C3B).
    static let ember = Color(red: 0.949, green: 0.361, blue: 0.231)

    /// Helles Gold für den Glanz in Titel-Verläufen (#F6C48A).
    static let glow = Color(red: 0.965, green: 0.769, blue: 0.541)

    // MARK: Farbtöne für Kategorien und Werkzeuge

    // Gleiche Helligkeit und Sättigung wie das Kupfer, nur andere Farbtöne —
    // so glüht jede Kategorie in ihrer Farbe, ohne aus dem Bild zu fallen.
    static let coral = Color(red: 0.941, green: 0.341, blue: 0.306)     // #F0574E
    static let gold = Color(red: 0.914, green: 0.706, blue: 0.298)      // #E9B44C
    static let sky = Color(red: 0.373, green: 0.659, blue: 0.914)       // #5FA8E9
    static let teal = Color(red: 0.373, green: 0.706, blue: 0.612)      // #5FB49C
    static let tan = Color(red: 0.788, green: 0.541, blue: 0.357)       // #C98A5B
    static let lime = Color(red: 0.612, green: 0.796, blue: 0.353)      // #9CCB5A
    static let rose = Color(red: 0.914, green: 0.478, blue: 0.545)      // #E97A8B
    static let ochre = Color(red: 0.847, green: 0.635, blue: 0.353)     // #D8A25A
    static let lavender = Color(red: 0.780, green: 0.608, blue: 0.878)  // #C79BE0
    static let peach = Color(red: 0.949, green: 0.651, blue: 0.353)     // #F2A65A
    static let ice = Color(red: 0.498, green: 0.718, blue: 0.851)       // #7FB7D9

    /// Der Farbton einer Kategorie, abgeleitet von ihrem Symbol — jede
    /// Standardkategorie bekommt ihr eigenes Glühen, eigene Kategorien
    /// laufen im Kupfer.
    static func categoryTint(iconName: String) -> Color {
        switch iconName {
        case "frying.pan": coral
        case "bird": gold
        case "fish": sky
        case "flame": copper
        case "smoke": tan
        case "stove": teal
        case "carrot": lime
        case "drop.fill": rose
        case "oven": ochre
        case "birthday.cake": lavender
        case "teddybear": peach
        case "mug": ice
        default: copper
        }
    }

    // MARK: Verläufe

    /// Kupfer → Glut-Rot für primäre Buttons und hervorgehobene Kacheln.
    static var copperGradient: LinearGradient {
        LinearGradient(
            colors: [copper, copper.mix(with: ember, by: 0.4)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Kupfer → Gold für große Titel (Begrüßung auf dem Dashboard).
    static var titleGradient: LinearGradient {
        LinearGradient(
            colors: [copper, glow],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    /// Dunkler Glut-Verlauf als Platzhalter für Rezepte ohne Foto.
    static var placeholderGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.227, green: 0.129, blue: 0.075), wood],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: Schatten

    /// Schatten unter Karten — auf dunklem Grund reines, weiches Schwarz.
    static var cardShadow: Color {
        Color.black.opacity(0.35)
    }

    /// Leuchtender Schatten unter Kupfer-Flächen (Buttons, Kacheln, Timer).
    static var glowShadow: Color {
        copper.opacity(0.35)
    }
}
