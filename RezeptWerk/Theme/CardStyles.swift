import SwiftUI

/// Karten-Stile — das wichtigste visuelle Element der App.
///
/// Eine „Karte“ ist eine angehobene Fläche mit warmem Hintergrund, feiner
/// Kontur und weichem, warmem Schatten. Alle Inhalte (Rezepte, Kategorien,
/// Import-Wege) liegen auf solchen Karten.

private struct CardModifier: ViewModifier {
    /// Innenabstand der Karte. `0` z. B. für Karten mit randlosem Bild.
    var padding: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppColors.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .overlay(
                // Feine Kontur, damit Karten auch im Dunkelmodus klar abgegrenzt sind.
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .strokeBorder(AppColors.separator, lineWidth: 1)
            )
            .shadow(color: AppColors.cardShadow, radius: 10, x: 0, y: 4)
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

    /// Abgesenkte kleine Fläche.
    func sunken() -> some View {
        modifier(SunkenModifier())
    }
}
