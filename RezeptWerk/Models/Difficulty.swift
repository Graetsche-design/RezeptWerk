import Foundation

/// Schwierigkeitsgrad eines Rezepts.
///
/// Als `Int`-Rohwert gespeichert (siehe `Recipe.difficultyRaw`) —
/// das ist die robusteste Variante für SwiftData.
enum Difficulty: Int, CaseIterable, Identifiable {
    case easy = 1
    case medium = 2
    case hard = 3

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .easy: "Einfach"
        case .medium: "Mittel"
        case .hard: "Anspruchsvoll"
        }
    }

    /// Kurzdarstellung mit Punkten für Badges: • / •• / •••
    var dots: String {
        String(repeating: "•", count: rawValue)
    }
}
