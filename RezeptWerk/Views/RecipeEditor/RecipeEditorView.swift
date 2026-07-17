import SwiftUI
import SwiftData

/// Der Rezepteditor — für drei Fälle derselbe Bildschirm:
/// 1. **Neues Rezept**: `RecipeEditorView(recipe: nil)`
/// 2. **Bearbeiten**: `RecipeEditorView(recipe: vorhandenes)`
/// 3. **Import-Korrektur**: `RecipeEditorView(recipe: nil, prefilledDraft: …)`
///
/// Der Editor arbeitet auf einem `RecipeDraft` (Arbeitskopie) —
/// „Abbrechen“ verwirft einfach den Draft, gespeichert wird zentral
/// über den `RecipeImportService`.
struct RecipeEditorView: View {

    /// Das zu bearbeitende Rezept — `nil` bedeutet: neues Rezept.
    let recipe: Recipe?

    /// Wird nach erfolgreichem Speichern aufgerufen (z. B. vom Import).
    var onSaved: ((Recipe) -> Void)? = nil

    @State private var draft: RecipeDraft

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \RecipeCategory.sortIndex)
    private var categories: [RecipeCategory]

    @State private var showSaveError = false

    init(recipe: Recipe?, prefilledDraft: RecipeDraft? = nil, onSaved: ((Recipe) -> Void)? = nil) {
        self.recipe = recipe
        self.onSaved = onSaved

        // Draft aufbauen: Import-Vorbefüllung > bestehendes Rezept > leer.
        if let prefilledDraft {
            _draft = State(initialValue: prefilledDraft)
        } else if let recipe {
            _draft = State(initialValue: RecipeDraft(recipe: recipe))
        } else {
            _draft = State(initialValue: RecipeDraft())
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                basicsSection
                imageSection
                categorySection

                Section {
                    IngredientsEditorList(draft: draft)
                } header: {
                    editableSectionHeader("Zutaten")
                }

                Section {
                    StepsEditorList(draft: draft)
                } header: {
                    editableSectionHeader("Zubereitungsschritte")
                }

                timesSection
                ratingSection
                mealTypeSection

                Section("Tags") {
                    TagEditorView(selectedTagNames: $draft.tagNames)
                }

                notesSection
                sourceSection
                sausageSection
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(recipe == nil ? "Neues Rezept" : "Rezept bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        save()
                    }
                    .fontWeight(.semibold)
                    .disabled(!draft.canSave)
                }
            }
            .alert("Rezept konnte nicht gespeichert werden", isPresented: $showSaveError) {
                Button("Verstanden", role: .cancel) {}
            } message: {
                Text("Bitte versuche es noch einmal. Falls das Problem bleibt: App beenden und neu öffnen.")
            }
        }
        // Verhindert, dass das Sheet versehentlich weggewischt wird
        // und Eingaben verloren gehen.
        .interactiveDismissDisabled()
    }

    // MARK: Abschnitte

    private var basicsSection: some View {
        Section("Grunddaten") {
            TextField("Titel, z. B. „Omas Gulasch“", text: $draft.title)
                .font(AppTypography.body.weight(.medium))

            Stepper("Portionen: \(draft.servings)", value: $draft.servings, in: 1...50)

            Picker("Schwierigkeit", selection: $draft.difficulty) {
                ForEach(Difficulty.allCases) { difficulty in
                    Text(difficulty.label).tag(difficulty)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var imageSection: some View {
        Section("Bild") {
            if !draft.imageDatas.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.s) {
                        ForEach(Array(draft.imageDatas.enumerated()), id: \.offset) { index, data in
                            RecipeImageView(data: data)
                                .frame(width: 92, height: 92)
                                .clipShape(RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous))
                                .overlay(alignment: .topTrailing) {
                                    Button {
                                        draft.imageDatas.remove(at: index)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 18))
                                            .foregroundStyle(.white, .black.opacity(0.55))
                                    }
                                    .padding(4)
                                }
                                .overlay(alignment: .bottomLeading) {
                                    if index == 0 {
                                        Text("Titelbild")
                                            .font(.system(size: 10, weight: .semibold))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(.black.opacity(0.5), in: Capsule())
                                            .padding(4)
                                    }
                                }
                        }
                    }
                }
            }

            if draft.imageDatas.count < 3 {
                PhotoPickerButton(maxSelection: 3 - draft.imageDatas.count, onPicked: { newImages in
                    draft.imageDatas.append(contentsOf: newImages)
                }) {
                    Label("Foto hinzufügen", systemImage: "photo.on.rectangle.angled")
                }
            }
        }
    }

    private var categorySection: some View {
        Section("Kategorie") {
            // Auswahl über die stabile `PersistentIdentifier` statt über das
            // @Model-Objekt — robuste Variante (siehe RecipeFilterSheet).
            Picker("Kategorie", selection: categorySelection) {
                Text("Keine").tag(nil as PersistentIdentifier?)
                ForEach(categories) { category in
                    Label(category.name, systemImage: category.iconName)
                        .tag(Optional(category.persistentModelID))
                }
            }

            if let category = draft.category, !category.sortedSubcategories.isEmpty {
                Picker("Unterkategorie", selection: subcategorySelection) {
                    Text("Keine").tag(nil as PersistentIdentifier?)
                    ForEach(category.sortedSubcategories) { subcategory in
                        Text(subcategory.name).tag(Optional(subcategory.persistentModelID))
                    }
                }
            }
        }
    }

    /// Verbindet den Kategorie-Picker mit `draft.category`.
    private var categorySelection: Binding<PersistentIdentifier?> {
        Binding(
            get: { draft.category?.persistentModelID },
            set: { newID in
                draft.category = categories.first { $0.persistentModelID == newID }
                draft.categoryChanged()
            }
        )
    }

    /// Verbindet den Unterkategorie-Picker mit `draft.subcategory`.
    private var subcategorySelection: Binding<PersistentIdentifier?> {
        Binding(
            get: { draft.subcategory?.persistentModelID },
            set: { newID in
                let subcategories = draft.category?.sortedSubcategories ?? []
                draft.subcategory = subcategories.first { $0.persistentModelID == newID }
            }
        )
    }

    private var timesSection: some View {
        Section("Zeiten (in Minuten)") {
            timeRow("Vorbereitung", text: $draft.prepMinutesText)
            timeRow("Gar-/Backzeit", text: $draft.cookMinutesText)
            timeRow("Ruhezeit", text: $draft.restMinutesText)
        }
    }

    private func timeRow(_ label: String, text: Binding<String>) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("–", text: text)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 70)
            Text("Min.")
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    private var ratingSection: some View {
        Section("Bewertung & Favorit") {
            HStack {
                Text("Bewertung")
                Spacer()
                RatingStarsView(rating: draft.rating, size: 22) { newRating in
                    draft.rating = newRating
                }
            }
            Toggle("Favorit", isOn: $draft.isFavorite)
                .tint(AppColors.copper)
        }
    }

    private var mealTypeSection: some View {
        Section {
            FlowLayout(spacing: AppSpacing.s) {
                ForEach(MealType.allCases) { type in
                    Button {
                        draft.toggleMealType(type)
                    } label: {
                        let isSelected = draft.suitableMealTypes.contains(type)
                        Label(type.label, systemImage: type.icon)
                            .font(AppTypography.caption.weight(.medium))
                            .foregroundStyle(isSelected ? .white : AppColors.textSecondary)
                            .padding(.horizontal, AppSpacing.m)
                            .padding(.vertical, AppSpacing.s)
                            .background(
                                isSelected ? AnyShapeStyle(AppColors.copper) : AnyShapeStyle(AppColors.backgroundSunken),
                                in: Capsule()
                            )
                            .overlay(
                                Capsule().strokeBorder(
                                    isSelected ? Color.clear : AppColors.separator,
                                    lineWidth: 1
                                )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, AppSpacing.xs)
        } header: {
            Text("Geeignet für (Wochenplan)")
        } footer: {
            Text("Bestimmt, bei welchen Mahlzeiten dieses Rezept im Wochenplan vorgeschlagen wird. Mehrfachauswahl möglich. Ohne Auswahl passt es überall.")
        }
    }

    private var notesSection: some View {
        Section("Notizen") {
            TextField(
                "Tipps, Abwandlungen, Erfahrungen …",
                text: $draft.notes,
                axis: .vertical
            )
            .lineLimit(3...8)
        }
    }

    private var sourceSection: some View {
        Section("Quelle") {
            TextField("z. B. „Omas Kochbuch, Seite 12“", text: $draft.sourceText)
            TextField("Link (https://…)", text: $draft.sourceURLText)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
    }

    private var sausageSection: some View {
        Section {
            Toggle("Fachdaten erfassen", isOn: $draft.includeSausageDetails)
                .tint(AppColors.copper)

            if draft.includeSausageDetails {
                SausageDetailsEditorSection(draft: draft)
            }
        } header: {
            Text("Wurst & Räuchern")
        } footer: {
            if !draft.includeSausageDetails {
                Text("Für Wurst-, Räucher- und Pökelrezepte: NPS-Menge, Kaliber, Temperaturen u. v. m. Wird bei der Kategorie „Wurst & Räuchern“ automatisch eingeblendet.")
            }
        }
    }

    /// Abschnitts-Kopf mit Bearbeiten-Button (zum Umsortieren/Löschen).
    private func editableSectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            EditButton()
                .font(AppTypography.caption)
        }
    }

    // MARK: Speichern

    private func save() {
        do {
            let saved = try RecipeImportService.save(draft: draft, updating: recipe, in: modelContext)
            onSaved?(saved)
            dismiss()
        } catch {
            showSaveError = true
        }
    }
}

#Preview("Neues Rezept") {
    RecipeEditorView(recipe: nil)
        .modelContainer(PreviewSupport.container)
}

#Preview("Bearbeiten") {
    RecipeEditorView(recipe: PreviewSupport.sausageRecipe)
        .modelContainer(PreviewSupport.container)
}
