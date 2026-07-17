import SwiftUI
import SwiftData

/// Die Detailansicht eines Rezepts — wie eine schön gesetzte Kochbuchseite:
/// Bild, Titel, Eckdaten, Zutaten mit Portionsrechner, Schritte,
/// Fachdaten (bei Wurst & Räuchern), Notizen und Quelle.
struct RecipeDetailView: View {

    let recipe: Recipe

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showEditor = false
    @State private var showCookingMode = false
    @State private var showDeleteConfirmation = false
    @State private var showExport = false
    @State private var showAddNote = false
    @State private var shoppingConfirmation: String?
    @State private var saveFailed = false

    /// Angezeigte Portionen für den Portionsrechner (0 = noch nicht gesetzt).
    @State private var displayedServings = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                headerImage
                titleBlock
                infoPills

                if !recipe.tagNames.isEmpty {
                    tagRow
                }

                if !recipe.sortedSteps.isEmpty {
                    Button {
                        showCookingMode = true
                    } label: {
                        Label("Kochmodus starten", systemImage: "flame.fill")
                    }
                    .buttonStyle(.rwPrimary)
                }

                if !recipe.sortedIngredients.isEmpty {
                    IngredientsSectionView(
                        recipe: recipe,
                        displayedServings: $displayedServings
                    )
                }

                if !recipe.sortedSteps.isEmpty {
                    StepsSectionView(recipe: recipe)
                }

                if let details = recipe.sausageDetails, details.hasAnyValue {
                    SausageDetailsSectionView(details: details)
                }

                if !recipe.notes.isEmpty {
                    notesCard
                }

                cookingNotesCard

                if !recipe.sourceText.isEmpty || recipe.sourceURL != nil {
                    sourceCard
                }

                metaFooter
            }
            .padding(.horizontal, AppSpacing.screen)
            .padding(.bottom, AppSpacing.xxl)
        }
        .screenBackground()
        .navigationBarTitleDisplayMode(.inline)
        .saveErrorAlert($saveFailed)
        .toolbar { toolbarContent }
        .sheet(isPresented: $showEditor) {
            RecipeEditorView(recipe: recipe)
        }
        .sheet(isPresented: $showExport) {
            RecipeExportView(recipe: recipe)
        }
        .sheet(isPresented: $showAddNote) {
            AddCookingNoteSheet(recipe: recipe)
        }
        .fullScreenCover(isPresented: $showCookingMode) {
            CookingModeView(recipe: recipe)
        }
        .confirmationDialog("Rezept löschen?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("„\(recipe.title)“ löschen", role: .destructive) {
                RecipeImportService.delete(recipe, in: modelContext)
                dismiss()
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Das Rezept wird dauerhaft von diesem Gerät gelöscht.")
        }
        .alert(
            "Zur Einkaufsliste",
            isPresented: Binding(
                get: { shoppingConfirmation != nil },
                set: { if !$0 { shoppingConfirmation = nil } }
            )
        ) {
            Button("Prima", role: .cancel) {}
        } message: {
            Text(shoppingConfirmation ?? "")
        }
        .onAppear {
            if displayedServings == 0 {
                displayedServings = recipe.servings
            }
        }
    }

    // MARK: Kopfbereich

    private var headerImage: some View {
        RecipeImageView(
            data: recipe.coverImageData,
            placeholderIcon: recipe.category?.iconName ?? "fork.knife"
        )
        .frame(height: 240)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .strokeBorder(AppColors.separator, lineWidth: 1)
        )
        .padding(.top, AppSpacing.s)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            if let category = recipe.category {
                HStack(spacing: AppSpacing.xs) {
                    Text(category.name)
                    if let subcategory = recipe.subcategory {
                        Text("· \(subcategory.name)")
                    }
                }
                .font(AppTypography.label)
                .textCase(.uppercase)
                .kerning(1.2)
                .foregroundStyle(AppColors.copper)
            }

            Text(recipe.title)
                .font(AppTypography.recipeTitle)
                .foregroundStyle(AppColors.textPrimary)

            // Bewertung — direkt antippbar.
            RatingStarsView(rating: recipe.rating, size: 20) { newRating in
                recipe.rating = newRating
                recipe.updatedAt = .now
                try? modelContext.save()
            }
        }
    }

    private var infoPills: some View {
        FlowLayout(spacing: AppSpacing.s) {
            if let prep = recipe.prepMinutes, prep > 0 {
                InfoPill(icon: "knife", text: "Vorbereitung \(FormatHelpers.minutesText(prep))")
            }
            if let cook = recipe.cookMinutes, cook > 0 {
                InfoPill(icon: "flame", text: "Garzeit \(FormatHelpers.minutesText(cook))")
            }
            if let rest = recipe.restMinutes, rest > 0 {
                InfoPill(icon: "hourglass", text: "Ruhezeit \(FormatHelpers.minutesText(rest))")
            }
            if recipe.totalMinutes > 0 {
                InfoPill(icon: "clock.fill", text: "Gesamt \(FormatHelpers.minutesText(recipe.totalMinutes))")
            }
            InfoPill(icon: "person.2", text: "\(recipe.servings) Portionen")
            DifficultyBadge(difficulty: recipe.difficulty)
            ForEach(recipe.suitableMealTypes) { mealType in
                InfoPill(icon: mealType.icon, text: mealType.label)
            }
        }
    }

    private var tagRow: some View {
        FlowLayout(spacing: AppSpacing.s) {
            ForEach(recipe.tagNames, id: \.self) { tag in
                TagChipView(text: tag)
            }
        }
    }

    // MARK: Notizen, Quelle, Meta

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            SectionHeaderView(title: "Notizen")
            Text(recipe.notes)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .card()
        }
    }

    /// Die datierten Koch-Notizen („Kochjournal“) — immer sichtbar, damit
    /// der „Hinzufügen“-Einstieg auffindbar bleibt.
    private var cookingNotesCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            SectionHeaderView(
                title: "Meine Koch-Notizen",
                actionTitle: "Hinzufügen",
                action: { showAddNote = true }
            )

            VStack(alignment: .leading, spacing: 0) {
                if recipe.sortedCookingNotes.isEmpty {
                    Text("Noch keine Notizen — halte fest, wie es geworden ist.")
                        .font(AppTypography.secondary)
                        .foregroundStyle(AppColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ForEach(recipe.sortedCookingNotes) { note in
                        cookingNoteRow(note)
                    }
                }
            }
            .card()
        }
    }

    /// Eine Notiz-Zeile: Datum, Text und Löschen-Knopf.
    private func cookingNoteRow(_ note: CookingNote) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: AppSpacing.s) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(FormatHelpers.shortDate(note.date))
                        .font(AppTypography.caption.weight(.semibold))
                        .foregroundStyle(AppColors.copper)

                    Text(note.text)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.textPrimary)
                }

                Spacer(minLength: 0)

                Button {
                    modelContext.delete(note)
                    do {
                        try modelContext.save()
                    } catch {
                        modelContext.rollback()
                        saveFailed = true
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(AppColors.textSecondary.opacity(0.55))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Notiz löschen")
            }
            .padding(.vertical, AppSpacing.s)

            Divider()
                .overlay(AppColors.separator.opacity(0.6))
        }
    }

    private var sourceCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            SectionHeaderView(title: "Quelle")
            VStack(alignment: .leading, spacing: AppSpacing.s) {
                if !recipe.sourceText.isEmpty {
                    Text(recipe.sourceText)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.textPrimary)
                }
                if let url = recipe.sourceURL {
                    Link(destination: url) {
                        Label(url.host() ?? url.absoluteString, systemImage: "safari")
                            .font(AppTypography.secondary)
                            .foregroundStyle(AppColors.copper)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .card()
        }
    }

    private var metaFooter: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Erstellt am \(FormatHelpers.shortDate(recipe.createdAt))")
            Text("Zuletzt geändert am \(FormatHelpers.shortDate(recipe.updatedAt))")
            if let lastCooked = recipe.lastCookedAt {
                Text("Zuletzt gekocht \(FormatHelpers.relativeDate(lastCooked))")
            }
        }
        .font(AppTypography.caption)
        .foregroundStyle(AppColors.textSecondary)
        .padding(.top, AppSpacing.s)
    }

    // MARK: Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            FavoriteButton(isFavorite: recipe.isFavorite) {
                recipe.isFavorite.toggle()
                try? modelContext.save()
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showExport = true
            } label: {
                Label("Teilen", systemImage: "square.and.arrow.up")
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button {
                    showEditor = true
                } label: {
                    Label("Bearbeiten", systemImage: "pencil")
                }
                Button {
                    showExport = true
                } label: {
                    Label("Teilen & Export", systemImage: "square.and.arrow.up")
                }
                Button {
                    let count = ShoppingListService.add(recipe: recipe, to: modelContext)
                    shoppingConfirmation = "\(count) Zutaten zur Einkaufsliste hinzugefügt."
                } label: {
                    Label("Zur Einkaufsliste", systemImage: "cart.badge.plus")
                }
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Löschen", systemImage: "trash")
                }
            } label: {
                Label("Mehr", systemImage: "ellipsis.circle")
            }
        }
    }
}

/// Kleines Sheet zum Anlegen einer Koch-Notiz aus der Detailansicht.
private struct AddCookingNoteSheet: View {

    let recipe: Recipe

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var text = ""
    @State private var saveFailed = false

    private var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Wie ist es gelaufen?") {
                    TextField(
                        "z. B. Nächstes Mal weniger Salz …",
                        text: $text,
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                }
            }
            .navigationTitle("Koch-Notiz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        let note = CookingNote(text: trimmedText)
                        note.recipe = recipe
                        modelContext.insert(note)
                        do {
                            try modelContext.save()
                        } catch {
                            modelContext.rollback()
                            saveFailed = true
                            return
                        }
                        dismiss()
                    }
                    .disabled(trimmedText.isEmpty)
                }
            }
            .saveErrorAlert($saveFailed)
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    NavigationStack {
        RecipeDetailView(recipe: PreviewSupport.sausageRecipe)
    }
    .modelContainer(PreviewSupport.container)
}
