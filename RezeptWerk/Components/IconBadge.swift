import SwiftUI

/// Symbol im getönten Kreis — die Signatur der Karten in „Dunkle Glut“.
///
/// Standard ist ein Kupfer-Schein hinter kupfernem Symbol; Kategorien und
/// Werkzeuge bringen ihren eigenen Farbton mit (`tint`). `filled` füllt die
/// Fläche mit dem Kupfer-Verlauf und setzt das Symbol weiß — für den einen
/// hervorgehobenen Zugang. `cornerRadius` macht aus dem Kreis ein
/// abgerundetes Quadrat (Werkzeug-Kacheln).
struct IconBadge: View {
    let systemName: String
    var size: CGFloat = 44
    var tint: Color = AppColors.copper
    var filled = false
    var cornerRadius: CGFloat? = nil

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: (size * 0.47).rounded(), weight: .medium))
            .foregroundStyle(filled ? Color.white : tint)
            .frame(width: size, height: size)
            .background {
                if let cornerRadius {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(fill)
                } else {
                    Circle()
                        .fill(fill)
                }
            }
    }

    private var fill: AnyShapeStyle {
        filled
            ? AnyShapeStyle(AppColors.copperGradient)
            : AnyShapeStyle(tint.opacity(0.2))
    }
}

#Preview {
    HStack(spacing: 16) {
        IconBadge(systemName: "calendar")
        IconBadge(systemName: "flame", tint: AppColors.coral)
        IconBadge(systemName: "thermometer.medium", size: 40, tint: AppColors.sky, cornerRadius: AppRadius.small)
        IconBadge(systemName: "square.and.pencil", filled: true)
    }
    .padding()
    .background(AppColors.backgroundPrimary)
}
