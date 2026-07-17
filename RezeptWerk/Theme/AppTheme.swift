import SwiftUI
import UIKit

/// Zentraler Einstiegspunkt ins Designsystem.
///
/// Hier liegt alles, was die App EINMAL global konfiguriert:
/// - die Serifenschrift in den Navigationsleisten,
/// - der warme Standard-Hintergrund für alle Bildschirme.
enum AppTheme {

    /// Konfiguriert die Navigationsleisten der ganzen App mit der
    /// Serifenschrift, damit auch System-Titel zum Kochbuch-Look passen.
    ///
    /// Hinweis: Das ist eine der zwei bewussten UIKit-Stellen der App —
    /// SwiftUI bietet (Stand iOS 18/26) keine Möglichkeit, die Schrift der
    /// Navigationsleiste direkt zu setzen. Der Aufruf erfolgt einmalig beim
    /// App-Start in `RezeptWerkApp`.
    static func configureNavigationBarAppearance() {
        let largeTitleFont = UIFont.preferredSerifFont(style: .largeTitle, weight: .bold)
        let titleFont = UIFont.preferredSerifFont(style: .headline, weight: .semibold)

        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.largeTitleTextAttributes = [.font: largeTitleFont]
        appearance.titleTextAttributes = [.font: titleFont]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }
}

private extension UIFont {
    /// Liefert die New-York-Serifenschrift im gewünschten Text-Style —
    /// inklusive Dynamic-Type-Skalierung.
    static func preferredSerifFont(style: UIFont.TextStyle, weight: UIFont.Weight) -> UIFont {
        let baseSize = UIFont.preferredFont(forTextStyle: style).pointSize
        let systemFont = UIFont.systemFont(ofSize: baseSize, weight: weight)
        guard let serifDescriptor = systemFont.fontDescriptor.withDesign(.serif) else {
            return systemFont
        }
        return UIFont(descriptor: serifDescriptor, size: baseSize)
    }
}

// MARK: - Bildschirm-Hintergrund

/// Legt den warmen Pergament-Hintergrund hinter einen kompletten Bildschirm.
private struct ScreenBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppColors.backgroundPrimary.ignoresSafeArea())
    }
}

extension View {
    /// Standard-Hintergrund für alle Bildschirme der App.
    func screenBackground() -> some View {
        modifier(ScreenBackgroundModifier())
    }
}
