import Foundation

/// Die Mahlzeit eines Tages im Wochenplan.
enum MealType: String, CaseIterable, Identifiable, Codable {
    case breakfast
    case lunch
    case dinner
    case snack

    var id: String { rawValue }

    var label: String {
        switch self {
        case .breakfast: "Frühstück"
        case .lunch: "Mittagessen"
        case .dinner: "Abendessen"
        case .snack: "Snack"
        }
    }

    /// Kurzform für enge Badges.
    var shortLabel: String {
        switch self {
        case .breakfast: "Früh"
        case .lunch: "Mittag"
        case .dinner: "Abend"
        case .snack: "Snack"
        }
    }

    var icon: String {
        switch self {
        case .breakfast: "sunrise"
        case .lunch: "sun.max"
        case .dinner: "moon.stars"
        case .snack: "carrot"
        }
    }

    /// Reihenfolge innerhalb eines Tages (Frühstück → Snack).
    var sortOrder: Int {
        switch self {
        case .breakfast: 0
        case .lunch: 1
        case .dinner: 2
        case .snack: 3
        }
    }

    /// Eigenes Bit für die Speicherung der Eignung als Bitmaske
    /// (`Recipe.mealTypeMask`). Frühstück = 1, Mittag = 2, Abend = 4, Snack = 8.
    var bit: Int { 1 << sortOrder }
}
