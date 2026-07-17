import SwiftUI

/// Die Hauptbereiche der App — Tabs auf dem iPhone, Sidebar auf dem iPad.
enum AppTab: String, Hashable, CaseIterable {
    case dashboard
    case recipes
    case planner
    case shoppingList
    case categories
    case favorites
    case importHub
    case settings
}

/// Aktion zum programmatischen Tab-Wechsel.
///
/// Beispiel: Der „Importieren“-Button auf dem Dashboard wechselt damit
/// direkt in den Import-Bereich:
/// ```swift
/// @Environment(\.switchTab) private var switchTab
/// Button("Importieren") { switchTab(.importHub) }
/// ```
struct TabSwitchAction {
    var switchTo: (AppTab) -> Void = { _ in }

    func callAsFunction(_ tab: AppTab) {
        switchTo(tab)
    }
}

extension EnvironmentValues {
    /// Wird von der `RootView` gesetzt.
    @Entry var switchTab = TabSwitchAction()
}
