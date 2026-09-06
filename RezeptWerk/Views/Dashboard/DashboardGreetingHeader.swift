import SwiftUI

/// Begrüßung auf dem Dashboard — Tageszeit-abhängig, mit Datum; der Gruß
/// glüht im Kupfer-Gold-Verlauf.
struct DashboardGreetingHeader: View {

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<11: return "Guten Morgen"
        case 11..<17: return "Guten Tag"
        case 17..<23: return "Guten Abend"
        default: return "Noch wach?"
        }
    }

    private var dateText: String {
        Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(dateText)
                .font(AppTypography.label)
                .textCase(.uppercase)
                .kerning(1.4)
                .foregroundStyle(AppColors.textSecondary)

            Text(greeting)
                .font(AppTypography.screenTitle)
                .foregroundStyle(AppColors.titleGradient)

            Text("Was kochen wir heute?")
                .font(AppTypography.secondary)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
