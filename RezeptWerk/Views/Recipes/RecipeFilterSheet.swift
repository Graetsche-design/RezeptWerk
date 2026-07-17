import SwiftUI
import SwiftData

/// Filter-Sheet der Rezeptliste: Kategorie, Unterkategorie, Schwierigkeit,
/// Favoriten und Tags.
struct RecipeFilterSheet: View {

    @Binding var filter: RecipeFilter

    @Query(sort: \RecipeCategory.sortIndex)
    private var categories: [RecipeCategory]

    @Query(sort: \RecipeTag.name)
    private var allTags: [RecipeTag]

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Kategorie") {
                    // Auswahl über die stabile `PersistentIdentifier` statt
                    // über das @Model-Objekt selbst — das ist die robuste
                    // Variante (SwiftUI-Picker mit optionalem @Model als Wert
                    // stolpert je nach Compiler-Zustand über dessen Hashable).
                    Picker("Kategorie", selection: categorySelection) {
                        Text("Alle Kategorien").tag(nil as PersistentIdentifier?)
                        ForEach(categories) { category in
                            Text(category.name).tag(Optional(category.persistentModelID))
                        }
                    }

                    if let category = filter.category, !category.sortedSubcategories.isEmpty {
                        Picker("Unterkategorie", selection: subcategorySelection) {
                            Text("Alle").tag(nil as PersistentIdentifier?)
                            ForEach(category.sortedSubcategories) { subcategory in
                                Text(subcategory.name).tag(Optional(subcategory.persistentModelID))
                            }
                        }
                    }
                }

                Section("Schwierigkeit") {
                    Picker("Schwierigkeit", selection: $filter.difficulty) {
                        Text("Alle").tag(nil as Difficulty?)
                        ForEach(Difficulty.allCases) { difficulty in
                            Text(difficulty.label).tag(Optional(difficulty))
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Toggle("Nur Favoriten", isOn: $filter.onlyFavorites)
                        .tint(AppColors.copper)
                }

                if !allTags.isEmpty {
                    Section("Tags") {
                        FlowLayout(spacing: AppSpacing.s) {
                            ForEach(allTags) { tag in
                                Button {
                                    toggleTag(tag.name)
                                } label: {
                                    TagChipView(
                                        text: tag.name,
                                        isSelected: filter.tagNames.contains(tag.name)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, AppSpacing.xs)
                    }
                }
            }
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Zurücksetzen") {
                        filter.reset()
                    }
                    .disabled(!filter.isActive)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: Auswahl-Bindungen (über PersistentIdentifier)

    /// Verbindet den Kategorie-Picker mit `filter.category`. Beim Wechsel
    /// wird eine nicht mehr passende Unterkategorie automatisch verworfen.
    private var categorySelection: Binding<PersistentIdentifier?> {
        Binding(
            get: { filter.category?.persistentModelID },
            set: { newID in
                let newCategory = categories.first { $0.persistentModelID == newID }
                filter.category = newCategory
                if let subcategory = filter.subcategory,
                   subcategory.category?.persistentModelID != newCategory?.persistentModelID {
                    filter.subcategory = nil
                }
            }
        )
    }

    /// Verbindet den Unterkategorie-Picker mit `filter.subcategory`.
    private var subcategorySelection: Binding<PersistentIdentifier?> {
        Binding(
            get: { filter.subcategory?.persistentModelID },
            set: { newID in
                let subcategories = filter.category?.sortedSubcategories ?? []
                filter.subcategory = subcategories.first { $0.persistentModelID == newID }
            }
        )
    }

    private func toggleTag(_ name: String) {
        if filter.tagNames.contains(name) {
            filter.tagNames.remove(name)
        } else {
            filter.tagNames.insert(name)
        }
    }
}
