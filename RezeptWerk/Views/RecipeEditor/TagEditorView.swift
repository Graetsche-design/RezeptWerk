import SwiftUI
import SwiftData

/// Tag-Auswahl im Editor: vorhandene Tags antippen, neue frei eingeben.
struct TagEditorView: View {

    @Binding var selectedTagNames: [String]

    @Query(sort: \RecipeTag.name)
    private var existingTags: [RecipeTag]

    @State private var newTagText = ""

    /// Alle anzeigbaren Tags: vorhandene plus frisch hinzugefügte
    /// (die noch nicht in der Datenbank sind), alphabetisch.
    private var allTagNames: [String] {
        var names = Set(existingTags.map(\.name))
        names.formUnion(selectedTagNames)
        return names.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }

    var body: some View {
        if !allTagNames.isEmpty {
            FlowLayout(spacing: AppSpacing.s) {
                ForEach(allTagNames, id: \.self) { name in
                    Button {
                        toggle(name)
                    } label: {
                        TagChipView(text: name, isSelected: isSelected(name))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, AppSpacing.xs)
        }

        HStack {
            TextField("Neues Tag, z. B. „Dutch Oven“", text: $newTagText)
                .onSubmit(addNewTag)

            Button("Hinzufügen", action: addNewTag)
                .disabled(newTagText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    private func isSelected(_ name: String) -> Bool {
        selectedTagNames.contains { $0.caseInsensitiveCompare(name) == .orderedSame }
    }

    private func toggle(_ name: String) {
        if isSelected(name) {
            selectedTagNames.removeAll { $0.caseInsensitiveCompare(name) == .orderedSame }
        } else {
            selectedTagNames.append(name)
        }
    }

    private func addNewTag() {
        let name = newTagText.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        if !isSelected(name) {
            selectedTagNames.append(name)
        }
        newTagText = ""
    }
}
