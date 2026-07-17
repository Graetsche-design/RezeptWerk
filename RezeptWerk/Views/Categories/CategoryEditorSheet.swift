import SwiftUI
import SwiftData

/// Sheet zum Anlegen einer eigenen Kategorie — oder zum Ergänzen von
/// Unterkategorien bei einer bestehenden.
///
/// Bei Standard-Kategorien (`isBuiltIn`) lässt sich der Name nicht ändern,
/// eigene Unterkategorien sind aber jederzeit möglich.
struct CategoryEditorSheet: View {

    /// `nil` = neue Kategorie anlegen.
    let category: RecipeCategory?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var selectedIcon = "fork.knife"
    @State private var newSubcategoryName = ""
    /// Neue Unterkategorien werden erst beim Speichern angelegt.
    @State private var pendingSubcategoryNames: [String] = []

    /// Eine handverlesene Auswahl passender Symbole.
    private let iconChoices = [
        "fork.knife", "frying.pan", "flame", "smoke", "oven", "stove",
        "fish", "bird", "carrot", "leaf", "drop.fill", "birthday.cake",
        "mug", "wineglass", "takeoutbag.and.cup.and.straw", "teddybear",
    ]

    private var isNewCategory: Bool { category == nil }

    private var canSave: Bool {
        if isNewCategory {
            return !name.trimmingCharacters(in: .whitespaces).isEmpty
        }
        // Bestehende Kategorie: Speichern lohnt sich, sobald etwas geändert wurde.
        return true
    }

    var body: some View {
        NavigationStack {
            Form {
                if isNewCategory {
                    Section("Name") {
                        TextField("z. B. „Fermentieren“", text: $name)
                    }

                    Section("Symbol") {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 52))], spacing: AppSpacing.s) {
                            ForEach(iconChoices, id: \.self) { icon in
                                Button {
                                    selectedIcon = icon
                                } label: {
                                    Image(systemName: icon)
                                        .font(.system(size: 19))
                                        .foregroundStyle(selectedIcon == icon ? .white : AppColors.copper)
                                        .frame(width: 46, height: 46)
                                        .background(
                                            selectedIcon == icon
                                                ? AnyShapeStyle(AppColors.copper)
                                                : AnyShapeStyle(AppColors.backgroundSunken),
                                            in: Circle()
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, AppSpacing.xs)
                    }
                } else if let category {
                    Section("Kategorie") {
                        LabeledContent("Name", value: category.name)
                        if category.isBuiltIn {
                            Text("Standard-Kategorien können nicht umbenannt werden — eigene Unterkategorien sind aber jederzeit möglich.")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                }

                Section("Unterkategorien") {
                    if let category {
                        ForEach(category.sortedSubcategories) { subcategory in
                            Text(subcategory.name)
                        }
                    }
                    ForEach(pendingSubcategoryNames, id: \.self) { pending in
                        HStack {
                            Text(pending)
                            Spacer()
                            Text("neu")
                                .font(AppTypography.caption.weight(.semibold))
                                .foregroundStyle(AppColors.copper)
                        }
                    }

                    HStack {
                        TextField("Neue Unterkategorie", text: $newSubcategoryName)
                            .onSubmit(addPendingSubcategory)
                        Button("Hinzufügen", action: addPendingSubcategory)
                            .disabled(newSubcategoryName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .navigationTitle(isNewCategory ? "Neue Kategorie" : "Kategorie ergänzen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") { save() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
        }
    }

    private func addPendingSubcategory() {
        let trimmed = newSubcategoryName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        if !pendingSubcategoryNames.contains(trimmed) {
            pendingSubcategoryNames.append(trimmed)
        }
        newSubcategoryName = ""
    }

    private func save() {
        // Noch nicht bestätigte Eingabe im Textfeld mitnehmen.
        addPendingSubcategory()

        let target: RecipeCategory
        if let category {
            target = category
        } else {
            let allCategories = (try? modelContext.fetch(FetchDescriptor<RecipeCategory>())) ?? []
            target = RecipeCategory(
                name: name.trimmingCharacters(in: .whitespaces),
                iconName: selectedIcon,
                sortIndex: (allCategories.map(\.sortIndex).max() ?? 0) + 1,
                isBuiltIn: false
            )
            modelContext.insert(target)
        }

        let existingCount = target.sortedSubcategories.count
        let newSubcategories = pendingSubcategoryNames.enumerated().map { offset, subName in
            RecipeSubcategory(name: subName, sortIndex: existingCount + offset)
        }
        // Optionales Array sicher ergänzen (kann nach iCloud-Sync nil sein).
        target.subcategories = (target.subcategories ?? []) + newSubcategories

        try? modelContext.save()
        dismiss()
    }
}
