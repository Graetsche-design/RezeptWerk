import SwiftUI
import UIKit

/// Zentrale Schrift-Stile von RezeptWerk.
///
/// Überschriften und Rezepttitel verwenden eine Serifenschrift — das gibt
/// der App den Charakter eines hochwertigen Kochbuchs. Fließtext und
/// Bedienelemente nutzen die klare Systemschrift.
///
/// Als Titelschrift kommt „Instrument Serif“ zum Einsatz, sobald sie mit
/// der App ausgeliefert wird (Schriftdatei im Projekt + `UIAppFonts` in der
/// Info.plist); solange sie fehlt, übernimmt die System-Serife New York.
/// Alle Stile basieren auf Text-Styles (`.title`, `.body`, …) und wachsen
/// dadurch automatisch mit der Dynamic-Type-Einstellung des Nutzers mit.
enum AppTypography {

    // MARK: Titelschrift

    /// PostScript-Name der eingebetteten Titelschrift — `nil`, wenn sie
    /// nicht im Bundle liegt.
    static let displayFontName: String? = {
        let name = "InstrumentSerif-Regular"
        return UIFont(name: name, size: 12) == nil ? nil : name
    }()

    /// Titelschrift in einem Text-Style (skaliert mit Dynamic Type).
    static func display(_ style: Font.TextStyle, weight: Font.Weight) -> Font {
        if let name = displayFontName {
            let baseSize = UIFont.preferredFont(forTextStyle: uiTextStyle(for: style)).pointSize
            return .custom(name, size: baseSize, relativeTo: style)
        }
        return .system(style, design: .serif).weight(weight)
    }

    /// Titelschrift in fester Größe (Kochmodus, unabhängig von Dynamic Type).
    static func display(size: CGFloat, weight: Font.Weight) -> Font {
        if let name = displayFontName {
            return .custom(name, fixedSize: size)
        }
        return .system(size: size, weight: weight, design: .serif)
    }

    /// UIKit-Pendant für die Navigationsleiste (siehe `AppTheme`).
    static func uiDisplayFont(style: UIFont.TextStyle, weight: UIFont.Weight) -> UIFont {
        let baseSize = UIFont.preferredFont(forTextStyle: style).pointSize
        if let name = displayFontName, let custom = UIFont(name: name, size: baseSize) {
            return custom
        }
        let systemFont = UIFont.systemFont(ofSize: baseSize, weight: weight)
        guard let serifDescriptor = systemFont.fontDescriptor.withDesign(.serif) else {
            return systemFont
        }
        return UIFont(descriptor: serifDescriptor, size: baseSize)
    }

    // MARK: Überschriften (Serif — Kochbuch-Charakter)

    /// Große Bildschirm-Überschrift, z. B. Begrüßung auf dem Dashboard.
    static let screenTitle: Font = display(.largeTitle, weight: .bold)

    /// Rezepttitel in der Detailansicht.
    static let recipeTitle: Font = display(.title, weight: .bold)

    /// Abschnitts-Überschriften („Zutaten“, „Zubereitung“ …).
    static let sectionTitle: Font = display(.title3, weight: .semibold)

    /// Titel auf Rezeptkarten.
    static let cardTitle: Font = display(.headline, weight: .semibold)

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
        display(size: 28 * scale, weight: .medium)
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

    // MARK: Helfer

    private static func uiTextStyle(for style: Font.TextStyle) -> UIFont.TextStyle {
        switch style {
        case .largeTitle: .largeTitle
        case .title: .title1
        case .title2: .title2
        case .title3: .title3
        case .headline: .headline
        case .subheadline: .subheadline
        case .callout: .callout
        case .footnote: .footnote
        case .caption: .caption1
        case .caption2: .caption2
        default: .body
        }
    }
}
