import SwiftUI

/// Bewertungssterne (0–5) in Kupfer.
///
/// - Ohne `onRate`: reine Anzeige (z. B. auf Karten).
/// - Mit `onRate`: antippbar (Editor/Detailansicht). Tippt man den bereits
///   gesetzten Stern erneut an, wird die Bewertung gelöscht (0 Sterne).
struct RatingStarsView: View {
    let rating: Int
    var size: CGFloat = 14
    var onRate: ((Int) -> Void)? = nil

    var body: some View {
        HStack(spacing: size < 14 ? 1 : 4) {
            ForEach(1...5, id: \.self) { star in
                if let onRate {
                    Button {
                        // Erneutes Antippen desselben Sterns setzt auf 0 zurück.
                        onRate(star == rating ? 0 : star)
                    } label: {
                        starImage(for: star)
                    }
                    .buttonStyle(.plain)
                } else {
                    starImage(for: star)
                }
            }
        }
    }

    private func starImage(for star: Int) -> some View {
        Image(systemName: star <= rating ? "star.fill" : "star")
            .font(.system(size: size))
            .foregroundStyle(star <= rating ? AppColors.copper : AppColors.textSecondary.opacity(0.45))
    }
}
