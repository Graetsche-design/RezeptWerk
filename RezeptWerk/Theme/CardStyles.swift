import SwiftUI

/// Karten-Stile — das wichtigste visuelle Element der App.
///
/// Eine „Karte“ ist eine dunkle, angehobene Fläche mit feiner Kontur und
/// weichem Schatten. Alle Inhalte (Rezepte, Kategorien, Import-Wege) liegen
/// auf solchen Karten. Die Glut-Karte hebt einzelne Flächen mit einer
/// kupfernen Kontur und Leuchtschatten hervor (z. B. den laufenden Timer).

private struct CardModifier: ViewModifier {
    /// Innenabstand der Karte. `0` z. B. für Karten mit randlosem Bild.
    var padding: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppColors.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .overlay(
                // Feine Kontur — auf dunklem Grund die eigentliche Abgrenzung.
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .strokeBorder(AppColors.separator, lineWidth: 1)
            )
            .shadow(color: AppColors.cardShadow, radius: 12, x: 0, y: 6)
    }
}

/// Karte mit glühender Kupfer-Kontur. `isActive == false` fällt auf die
/// normale Karte zurück — praktisch für Zustände wie „Timer läuft“.
private struct GlowCardModifier: ViewModifier {
    var padding: CGFloat
    var isActive: Bool

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppColors.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .strokeBorder(
                        isActive ? AppColors.copper.opacity(0.45) : AppColors.separator,
                        lineWidth: isActive ? 1.5 : 1
                    )
            )
            .shadow(
                color: isActive ? AppColors.glowShadow : AppColors.cardShadow,
                radius: 18, x: 0, y: 8
            )
    }
}

/// Abgesenkte Fläche, z. B. für Info-Pills oder Eingabe-Hintergründe.
private struct SunkenModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppColors.backgroundSunken)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous))
    }
}

extension View {
    /// Standard-Karte mit Innenabstand.
    func card(padding: CGFloat = AppSpacing.l) -> some View {
        modifier(CardModifier(padding: padding))
    }

    /// Karte ohne Innenabstand — für Karten, deren Bild bis an den Rand geht.
    func cardNoPadding() -> some View {
        modifier(CardModifier(padding: 0))
    }

    /// Karte mit glühender Kupfer-Kontur und Leuchtschatten.
    func glowCard(padding: CGFloat = AppSpacing.l, isActive: Bool = true) -> some View {
        modifier(GlowCardModifier(padding: padding, isActive: isActive))
    }

    /// Abgesenkte kleine Fläche.
    func sunken() -> some View {
        modifier(SunkenModifier())
    }
}
