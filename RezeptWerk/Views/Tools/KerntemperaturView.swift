import SwiftUI

/// Der Kerntemperatur-Spickzettel: eine Offline-Nachschlagetabelle mit
/// Gar-Temperaturen für Fleisch, Fisch sowie Wurst & Räuchern.
///
/// Die Inhalte stehen in `KerntemperaturData` — die View zeigt sie nur an.
/// Bewusst OHNE eigenen `NavigationStack`: die Ansicht lebt im Stack des
/// Dashboards (gleiches Muster wie `WeekPlannerView`).
struct KerntemperaturView: View {

    @State private var searchText = ""

    /// Gruppen, gefiltert nach dem Suchtext. Gruppen ohne Treffer
    /// verschwinden ganz; ohne Suchtext bleibt alles sichtbar.
    private var filteredGroups: [TemperatureGroup] {
        let trimmed = searchText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return KerntemperaturData.groups }

        return KerntemperaturData.groups.compactMap { group in
            let entries = group.entries.filter { entry in
                entry.name.localizedCaseInsensitiveContains(trimmed)
                    || group.title.localizedCaseInsensitiveContains(trimmed)
                    || (entry.note?.localizedCaseInsensitiveContains(trimmed) ?? false)
            }
            guard !entries.isEmpty else { return nil }
            return TemperatureGroup(title: group.title, icon: group.icon, entries: entries)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                if filteredGroups.isEmpty {
                    EmptyStateView(
                        icon: "thermometer.medium",
                        title: "Keine Treffer",
                        message: "Zu „\(searchText)“ wurde nichts gefunden. Suche z. B. nach „Steak“, „Lachs“ oder „Pulled Pork“."
                    )
                } else {
                    ForEach(filteredGroups) { group in
                        groupSection(group)
                    }

                    safetyBox
                }
            }
            .padding(.horizontal, AppSpacing.screen)
            .padding(.top, AppSpacing.l)
            .padding(.bottom, AppSpacing.xxl)
        }
        .screenBackground()
        .navigationTitle("Kerntemperaturen")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Gericht oder Fleischsorte suchen …")
    }

    // MARK: Bausteine

    /// Eine Gruppe: Überschrift + Karte mit allen Temperatur-Zeilen.
    private func groupSection(_ group: TemperatureGroup) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            SectionHeaderView(title: group.title)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(group.entries) { entry in
                    row(entry)
                }
            }
            .card()
        }
    }

    /// Eine Beschriftung-Wert-Zeile (Muster wie im Fachdaten-Block).
    private func row(_ entry: TemperatureEntry) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.name)
                        .font(AppTypography.secondary)
                        .foregroundStyle(AppColors.textSecondary)

                    if let note = entry.note {
                        Text(note)
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary.opacity(0.8))
                    }
                }

                Spacer(minLength: AppSpacing.m)

                Text(entry.range)
                    .font(AppTypography.body.weight(.medium))
                    .foregroundStyle(AppColors.textPrimary)
                    .multilineTextAlignment(.trailing)
            }
            .padding(.vertical, AppSpacing.s)

            Divider()
                .overlay(AppColors.separator.opacity(0.6))
        }
    }

    /// Hinweis-Box am Ende (Muster: Sicherheits-Box der Fachdaten).
    private var safetyBox: some View {
        HStack(alignment: .top, spacing: AppSpacing.m) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 20))
                .foregroundStyle(AppColors.copper)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Gut zu wissen")
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(AppColors.textPrimary)
                Text("Alle Angaben sind bewährte Richtwerte. Geflügel, Hackfleisch und Wildschwein immer sicher durchgaren — und das Thermometer an der dicksten Stelle einstechen.")
                    .font(AppTypography.secondary)
                    .foregroundStyle(AppColors.textPrimary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.l)
        .background(AppColors.copper.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .strokeBorder(AppColors.copper.opacity(0.35), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        KerntemperaturView()
    }
}
