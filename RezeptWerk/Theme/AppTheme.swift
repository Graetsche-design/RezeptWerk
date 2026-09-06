import SwiftUI
import UIKit

/// Zentraler Einstiegspunkt ins Designsystem.
///
/// Hier liegt alles, was die App EINMAL global konfiguriert:
/// - die Serifenschrift (und Cremefarbe) in den Navigationsleisten,
/// - der dunkle Standard-Hintergrund für alle Bildschirme, auf Wunsch mit
///   Glut-Schein.
enum AppTheme {

    /// Konfiguriert die Navigationsleisten der ganzen App mit der
    /// Titelschrift, damit auch System-Titel zum Kochbuch-Look passen.
    ///
    /// Hinweis: Das ist eine der zwei bewussten UIKit-Stellen der App —
    /// SwiftUI bietet (Stand iOS 18/26) keine Möglichkeit, die Schrift der
    /// Navigationsleiste direkt zu setzen. Der Aufruf erfolgt einmalig beim
    /// App-Start in `RezeptWerkApp`.
    static func configureNavigationBarAppearance() {
        let largeTitleFont = AppTypography.uiDisplayFont(style: .largeTitle, weight: .bold)
        let titleFont = AppTypography.uiDisplayFont(style: .headline, weight: .semibold)
        let titleColor = UIColor(AppColors.textPrimary)

        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.largeTitleTextAttributes = [.font: largeTitleFont, .foregroundColor: titleColor]
        appearance.titleTextAttributes = [.font: titleFont, .foregroundColor: titleColor]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }
}

// MARK: - Bildschirm-Hintergrund

/// Legt den dunklen Grund hinter einen kompletten Bildschirm — optional mit
/// einem weichen Glut-Schein an einer Ecke (Dashboard, Detailansicht) oder
/// oben (Kochmodus).
private struct ScreenBackgroundModifier: ViewModifier {
    var glowAt: UnitPoint?

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    AppColors.backgroundPrimary
                    if let glowAt {
                        RadialGradient(
                            colors: [AppColors.copper.opacity(0.32), .clear],
                            center: glowAt,
                            startRadius: 0,
                            endRadius: 340
                        )
                    }
                }
                .ignoresSafeArea()
            }
    }
}

extension View {
    /// Standard-Hintergrund für alle Bildschirme; `glowAt` setzt den
    /// Glut-Schein, z. B. `.topTrailing` auf dem Dashboard.
    func screenBackground(glowAt: UnitPoint? = nil) -> some View {
        modifier(ScreenBackgroundModifier(glowAt: glowAt))
    }
}
