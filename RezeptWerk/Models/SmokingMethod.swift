import Foundation

/// Räucherart bei Wurst- und Räucherrezepten.
enum SmokingMethod: String, CaseIterable, Identifiable {
    case none
    case cold
    case warm
    case hot

    var id: String { rawValue }

    var label: String {
        switch self {
        case .none: "Ohne Räuchern"
        case .cold: "Kalträuchern"
        case .warm: "Warmräuchern"
        case .hot: "Heißräuchern"
        }
    }

    /// Übliche Temperaturspanne als Hilfetext im Editor.
    var temperatureHint: String {
        switch self {
        case .none: ""
        case .cold: "15–25 °C"
        case .warm: "30–50 °C"
        case .hot: "60–90 °C"
        }
    }
}
