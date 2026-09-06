import SwiftUI

/// Die Detailseite eines Hilfe-Themas — gut lesbar im Kochbuch-Stil.
struct HelpTopicDetailView: View {

    let topic: HelpTopic

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.l) {
                header

                ForEach(Array(topic.blocks.enumerated()), id: \.offset) { _, block in
                    blockView(block)
                }
            }
            .padding(.horizontal, AppSpacing.screen)
            .padding(.vertical, AppSpacing.l)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .screenBackground()
        .navigationTitle(topic.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        HStack(spacing: AppSpacing.m) {
            Image(systemName: topic.icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(AppColors.copper)
                .frame(width: 52, height: 52)
                .background(AppColors.copper.opacity(0.18), in: Circle())

            Text(topic.title)
                .font(AppTypography.recipeTitle)
                .foregroundStyle(AppColors.textPrimary)
        }
        .padding(.bottom, AppSpacing.s)
    }

    // MARK: Block-Darstellung

    @ViewBuilder
    private func blockView(_ block: HelpBlock) -> some View {
        switch block {
        case .paragraph(let text):
            Text(text)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

        case .heading(let text):
            SectionHeaderView(title: text)
                .padding(.top, AppSpacing.s)

        case .bullets(let items):
            VStack(alignment: .leading, spacing: AppSpacing.s) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .firstTextBaseline, spacing: AppSpacing.s) {
                        Text("•")
                            .font(AppTypography.body.weight(.bold))
                            .foregroundStyle(AppColors.copper)
                        Text(item)
                            .font(AppTypography.body)
                            .foregroundStyle(AppColors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }

        case .steps(let items):
            VStack(alignment: .leading, spacing: AppSpacing.m) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .top, spacing: AppSpacing.m) {
                        Text("\(index + 1)")
                            .font(AppTypography.body.weight(.semibold))
                            .foregroundStyle(AppColors.copper)
                            .frame(width: 28, height: 28)
                            .background(
                                Circle().strokeBorder(AppColors.copper.opacity(0.5), lineWidth: 1.5)
                            )
                        Text(item)
                            .font(AppTypography.body)
                            .foregroundStyle(AppColors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 3)
                    }
                }
            }

        case .tip(let text):
            HStack(alignment: .top, spacing: AppSpacing.m) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(AppColors.copper)
                Text(text)
                    .font(AppTypography.secondary)
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(AppSpacing.l)
            .background(AppColors.copper.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .strokeBorder(AppColors.copper.opacity(0.35), lineWidth: 1)
            )
        }
    }
}

#Preview {
    NavigationStack {
        HelpTopicDetailView(topic: HelpContent.topics[0])
    }
}
