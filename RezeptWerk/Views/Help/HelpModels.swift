import Foundation

/// Ein Thema der In-App-Anleitung (z. B. „Kochmodus“).
struct HelpTopic: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    /// Kurzbeschreibung für die Themenübersicht.
    let summary: String
    /// Die Inhaltsblöcke der Detailseite.
    let blocks: [HelpBlock]

    /// Gesamttext für die Suche (Titel + Zusammenfassung + alle Blöcke).
    var searchableText: String {
        ([title, summary] + blocks.flatMap(\.plainText)).joined(separator: " ")
    }
}

/// Ein Inhaltsbaustein einer Hilfe-Seite.
///
/// Wird in der Detailseite über den Index (`enumerated()`) iteriert, daher
/// keine `Identifiable`-Konformanz nötig.
enum HelpBlock {
    /// Normaler Absatz.
    case paragraph(String)
    /// Zwischenüberschrift (mit kupfernem Unterstrich).
    case heading(String)
    /// Aufzählung mit Punkten.
    case bullets([String])
    /// Nummerierte Schritt-für-Schritt-Anleitung.
    case steps([String])
    /// Hervorgehobener Tipp-Kasten.
    case tip(String)

    /// Reiner Text für die Suche.
    var plainText: [String] {
        switch self {
        case .paragraph(let text), .heading(let text), .tip(let text):
            [text]
        case .bullets(let items), .steps(let items):
            items
        }
    }
}
