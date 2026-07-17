import SwiftUI
import SwiftData

/// Kategorien-Übersicht (Tab bzw. Sidebar-Bereich) — mit der Möglichkeit,
/// eigene Kategorien anzulegen.
struct CategoriesView: View {

    @Query(sort: \RecipeCategory.sortIndex)
    private var categories: [RecipeCategory]

    @Environment(\.modelContext) private var modelContext
    @State private var showNewCategorySheet = false
    @State private var categoryToDelete: RecipeCategory?
    @State private var saveFailed = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 220), spacing: AppSpacing.m)],
                    spacing: AppSpacing.m
                ) {
                    ForEach(categories) { category in
                        NavigationLink(value: category) {
                            CategoryTileView(category: category)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            if !category.isBuiltIn {
                                Button(role: .destructive) {
                                    categoryToDelete = category
                                } label: {
                                    Label("Kategorie löschen", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .padding(AppSpacing.screen)
            }
            .screenBackground()
            .navigationTitle("Kategorien")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showNewCategorySheet = true
                    } label: {
                        Label("Neue Kategorie", systemImage: "plus")
                    }
                }
            }
            .navigationDestination(for: RecipeCategory.self) { category in
                CategoryRecipesView(category: category)
            }
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(recipe: recipe)
            }
            .sheet(isPresented: $showNewCategorySheet) {
                CategoryEditorSheet(category: nil)
            }
            .confirmationDialog(
                "Kategorie löschen?",
                isPresented: Binding(
                    get: { categoryToDelete != nil },
                    set: { if !$0 { categoryToDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("„\(categoryToDelete?.name ?? "")“ löschen", role: .destructive) {
                    if let category = categoryToDelete {
                        modelContext.delete(category)
                        do {
                            try modelContext.save()
                        } catch {
                            modelContext.rollback()
                            saveFailed = true
                        }
                    }
                    categoryToDelete = nil
                }
                Button("Abbrechen", role: .cancel) {
                    categoryToDelete = nil
                }
            } message: {
                Text("Die Rezepte bleiben erhalten — sie verlieren nur die Zuordnung zu dieser Kategorie.")
            }
            .saveErrorAlert($saveFailed)
        }
    }
}

#Preview {
    CategoriesView()
        .modelContainer(PreviewSupport.container)
}
