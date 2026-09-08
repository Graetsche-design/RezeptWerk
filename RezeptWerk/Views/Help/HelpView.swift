import SwiftUI

/// Die Themenübersicht der In-App-Anleitung — durchsuchbar, damit man jeden
/// Punkt schnell findet.
///
/// Bringt **keinen** eigenen `NavigationStack` mit; sie wird aus den
/// Einstellungen heraus angezeigt (deren Stack stellt die Navigation bereit).
struct HelpView: View {

    @State private var searchText = ""

    private var topics: [HelpTopic] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return HelpContent.topics }
        return HelpContent.topics.filter {
            $0.searchableText.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        List {
            if topics.isEmpty {
                Section {
                    Text("Kein Thema zu „\(searchText)“ gefunden.")
                        .font(AppTypography.secondary)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .listRowBackground(AppColors.backgroundElevated)
            } else {
                Section {
                    ForEach(topics) { topic in
                        NavigationLink {
                            HelpTopicDetailView(topic: topic)
                        } label: {
                            row(for: topic)
                        }
                    }
                }
                .listRowBackground(AppColors.backgroundElevated)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppColors.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("Anleitung & Hilfe")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Thema oder Stichwort suchen …")
    }

    private func row(for topic: HelpTopic) -> some View {
        HStack(spacing: AppSpacing.m) {
            Image(systemName: topic.icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(AppColors.copper)
                .frame(width: 36, height: 36)
                .background(AppColors.copper.opacity(0.18), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(topic.title)
                    .font(AppTypography.body.weight(.medium))
                    .foregroundStyle(AppColors.textPrimary)
                Text(topic.summary)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        HelpView()
    }
}
