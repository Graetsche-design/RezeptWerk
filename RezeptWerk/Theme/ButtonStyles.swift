import SwiftUI

/// Button-Stile von RezeptWerk.
///
/// Es gibt genau zwei Stile, damit die Oberfläche ruhig bleibt:
/// - **Primär** (Kupfer): die wichtigste Aktion eines Bildschirms.
/// - **Sekundär** (Kontur): alle weiteren Aktionen.

/// Großer Kupfer-Button für die Hauptaktion („Kochmodus starten“, „Speichern“).
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(AppColors.copperGradient)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous))
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// Ruhiger Kontur-Button für sekundäre Aktionen.
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(AppColors.textPrimary)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(AppColors.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
                    .strokeBorder(AppColors.wood.opacity(0.45), lineWidth: 1.5)
            )
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// Komfort-Zugriff: `.buttonStyle(.rwPrimary)` statt `.buttonStyle(PrimaryButtonStyle())`.
extension ButtonStyle where Self == PrimaryButtonStyle {
    static var rwPrimary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var rwSecondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}
