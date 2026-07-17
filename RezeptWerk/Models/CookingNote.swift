import Foundation
import SwiftData

/// Eine datierte Koch-Notiz zu einem Rezept — das „Kochjournal“.
///
/// Beispiel: „12.07.: Nächstes Mal weniger Salz.“ Notizen entstehen auf
/// der Abschlussseite des Kochmodus oder über „Hinzufügen“ in der
/// Rezept-Detailansicht. Alle Felder haben Standardwerte und der
/// Rückverweis ist optional — Voraussetzung für die iCloud-Synchronisierung.
@Model
final class CookingNote {

    /// Wann die Notiz entstanden ist.
    var date: Date = Date.now

    /// Der Notiztext.
    var text: String = ""

    /// Rückverweis aufs Rezept. Die `inverse`-Deklaration liegt bei `Recipe`.
    var recipe: Recipe?

    init(date: Date = .now, text: String = "") {
        self.date = date
        self.text = text
    }
}
