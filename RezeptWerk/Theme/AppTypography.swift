import SwiftUI

/// Zentrale Schrift-Stile von RezeptWerk.
///
/// Überschriften und Rezepttitel verwenden eine Serifenschrift (New York) —
/// das gibt der App den Charakter eines hochwertigen Kochbuchs.
/// Fließtext und Bedienelemente nutzen die klare Systemschrift.
///
/// Alle Stile basieren auf Text-Styles (`.title`, `.body`, …) und wachsen
/// dadurch automatisch mit der Dynamic-Type-Einstellung des Nutzers mit.
enum AppTypography {

    // MARK: Überschriften (Serif — Kochbuch-Charakter)

    /// Große Bildschirm-Überschrift, z. B. Begrüßung auf dem Dashboard.
    static let screenTitle: Font = .system(.largeTitle, design: .serif).weight(.bold)

    /// Rezepttitel in der Detailansicht.
    static let recipeTitle: Font = .system(.title, design: .serif).weight(.bold)

    /// Abschnitts-Überschriften („Zutaten“, „Zubereitung“ …).
    static let sectionTitle: Font = .system(.title3, design: .serif).weight(.semibold)

    /// Titel auf Rezeptkarten.
    static let cardTitle: Font = .system(.headline, design: .serif).weight(.semibold)

    // MARK: Text (Systemschrift — gut lesbar)

    /// Normaler Fließtext.
    static let body: Font = .system(.body)

    /// Nebentext, z. B. Zutatenmengen, Datumsangaben.
    static let secondary: Font = .system(.subheadline)

    /// Kleine Beschriftungen und Metadaten.
    static let caption: Font = .system(.caption)

    /// Kleine GROSSBUCHSTABEN-Beschriftung, z. B. Kategorie über dem Titel.
    /// (Verwendung zusammen mit `.textCase(.uppercase)` und `.kerning(1)`.)
    static let label: Font = .system(.caption, design: .default).weight(.semibold)

    // MARK: Kochmodus (feste Größen, über Einstellungen skalierbar)

    /// Schritttext im Kochmodus. `scale` kommt aus den Einstellungen
    /// (Normal / Groß / Sehr groß), damit der Text am Herd aus der
    /// Entfernung lesbar ist — bewusst unabhängig von Dynamic Type.
    static func cookingStep(scale: Double) -> Font {
        .system(size: 28 * scale, weight: .medium, design: .serif)
    }

    /// Begleittext im Kochmodus (Schrittzähler, Zutaten).
    static func cookingMeta(scale: Double) -> Font {
        .system(size: 17 * scale, weight: .regular)
    }

    /// Große Timer-Ziffern im Kochmodus.
    static func cookingTimer(scale: Double) -> Font {
        .system(size: 44 * scale, weight: .semibold, design: .rounded)
            .monospacedDigit()
    }
}
