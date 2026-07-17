import Foundation

/// Alle Fehler, die beim Importieren auftreten können — mit freundlichen,
/// verständlichen deutschen Meldungen und einem konkreten Tipp.
enum ImportError: LocalizedError {
    /// Im Bild/PDF/Text wurde kein verwertbarer Text gefunden.
    case noTextFound
    /// Das Bild konnte nicht gelesen werden.
    case imageUnreadable
    /// Das PDF konnte nicht geöffnet werden (beschädigt oder geschützt).
    case pdfUnreadable
    /// Die eingegebene Adresse ist keine gültige Web-Adresse.
    case invalidURL
    /// Die Webseite konnte nicht geladen werden.
    case webPageUnreachable
    /// Die Webseite enthält keine erkennbaren Rezeptdaten.
    case noRecipeDataFound
    /// Die Zwischenablage enthält keinen (ausreichenden) Text.
    case clipboardEmpty

    var errorDescription: String? {
        switch self {
        case .noTextFound:
            "Es wurde leider kein Text erkannt."
        case .imageUnreadable:
            "Das Bild konnte nicht gelesen werden."
        case .pdfUnreadable:
            "Das PDF konnte nicht gelesen werden."
        case .invalidURL:
            "Das ist leider keine gültige Web-Adresse."
        case .webPageUnreachable:
            "Die Webseite konnte nicht geladen werden."
        case .noRecipeDataFound:
            "Auf der Webseite wurden keine Rezeptdaten gefunden."
        case .clipboardEmpty:
            "Es wurde kein Text zum Erkennen eingefügt."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .noTextFound:
            "Tipp: Fotografiere das Rezept bei gutem Licht, möglichst gerade von oben — und achte darauf, dass der Text scharf ist."
        case .imageUnreadable:
            "Tipp: Wähle ein anderes Foto aus oder fotografiere das Rezept neu."
        case .pdfUnreadable:
            "Tipp: Prüfe, ob sich das PDF in einer anderen App öffnen lässt. Passwortgeschützte PDFs werden nicht unterstützt."
        case .invalidURL:
            "Tipp: Kopiere die Adresse direkt aus dem Browser, z. B. „https://www.chefkoch.de/…“."
        case .webPageUnreachable:
            "Tipp: Prüfe deine Internetverbindung und versuche es noch einmal."
        case .noRecipeDataFound:
            "Tipp: Kopiere den Rezepttext von der Seite und nutze stattdessen den Import aus der Zwischenablage."
        case .clipboardEmpty:
            "Tipp: Kopiere zuerst den Rezepttext (Text markieren → Kopieren) und füge ihn dann hier ein."
        }
    }
}
