import SwiftUI

/// Die Rezepte einer Kategorie — mit Unterkategorie-Chips zum Eingrenzen.
struct CategoryRecipesView: View {

    let category: RecipeCategory

    @State private var selectedSubcategory: RecipeSubcategory?
    @State private var showEditorSheet = false

    private var recipes: [Recipe] {
        let base: [Recipe]
        if let selectedSubcategory {
            base = category.recipeList.filter { $0.subcategory === selectedSubcategory }
        } else {
            base = category.recipeList
        }
        return base.sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.l) {
                if !category.sortedSubcategories.isEmpty {
                    subcategoryChips
                }

                if recipes.isEmpty {
                    EmptyStateView(
                        icon: category.iconName,
                        title: "Noch nichts hier",
                        message: selectedSubcategory == nil
                            ? "In „\(category.name)“ gibt es noch keine Rezepte."
                            : "In „\(selectedSubcategory?.name ?? "")“ gibt es noch keine Rezepte."
                    )
                } else {
                    LazyVStack(spacing: AppSpacing.m) {
                        ForEach(recipes) { recipe in
                            NavigationLink(value: recipe) {
                                RecipeCardView(recipe: recipe)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(AppSpacing.screen)
        }
        .screenBackground()
        .navigationTitle(category.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showEditorSheet = true
                } label: {
                    Label("Unterkategorien bearbeiten", systemImage: "slider.horizontal.3")
                }
            }
        }
        .sheet(isPresented: $showEditorSheet) {
            CategoryEditorSheet(category: category)
        }
    }

    /// Chips: „Alle“ + alle Unterkategorien.
    private var subcategoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.s) {
                Button {
                    selectedSubcategory = nil
                } label: {
                    TagChipView(text: "Alle", isSelected: selectedSubcategory == nil)
                }
                .buttonStyle(.plain)

                ForEach(category.sortedSubcategories) { subcategory in
                    Button {
                        selectedSubcategory = subcategory
                    } label: {
                        TagChipView(
                            text: subcategory.name,
                            isSelected: selectedSubcategory === subcategory
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
