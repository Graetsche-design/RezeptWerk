import SwiftUI
import UIKit

/// Zeigt das Foto eines Rezepts — oder einen stilvollen Platzhalter
/// (warmer Holz-Verlauf mit Kategorie-Symbol), wenn kein Foto existiert.
///
/// Verwendung: Der Aufrufer setzt `.frame(...)` und das Zuschneiden,
/// z. B. `RecipeImageView(...).frame(height: 200).clipped()`.
struct RecipeImageView: View {
    /// Die Bilddaten (JPEG/PNG) oder `nil` für den Platzhalter.
    let data: Data?

    /// SF-Symbol für den Platzhalter, idealerweise das Kategorie-Icon.
    var placeholderIcon: String = "fork.knife"

    var body: some View {
        if let data, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                AppColors.placeholderGradient
                Image(systemName: placeholderIcon)
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
    }
}

#Preview("Platzhalter") {
    RecipeImageView(data: nil, placeholderIcon: "flame")
        .frame(width: 240, height: 150)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .padding()
}
