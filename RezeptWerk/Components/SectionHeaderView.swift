import SwiftUI

/// Abschnitts-Überschrift im Kochbuch-Stil: Serifenschrift mit kurzem
/// kupfernem Unterstrich — die „handwerkliche Signatur“ der App.
/// Optional mit Aktion rechts („Alle anzeigen“).
struct SectionHeaderView: View {
    let title: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(AppTypography.sectionTitle)
                    .foregroundStyle(AppColors.textPrimary)

                RoundedRectangle(cornerRadius: 1.5)
                    .fill(AppColors.copper)
                    .frame(width: 30, height: 3)
            }

            Spacer()

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(AppTypography.secondary.weight(.medium))
                        .foregroundStyle(AppColors.copper)
                }
            }
        }
    }
}
