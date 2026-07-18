import SwiftUI
import SwiftData

/// Die Rezeptübersicht: Suche, Filter und adaptives Layout —
/// Kartenliste auf dem iPhone, Grid auf dem iPad.
struct RecipeListView: View {

    @Query(sort: \Recipe.createdAt, order: .reverse)
    private var allRecipes: [Recipe]

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.modelContext) private var modelContext

    @State private var searchText = ""
    @State private var filter = RecipeFilter()
    @State private var showFilterSheet = false
    @State private var showNewRecipeEditor = false
    @State private var recipeToEdit: Recipe?
    @State private var recipeToDelete: Recipe?

    /// Zeigt den Hinweis, wenn das Löschen nicht gespeichert werden konnte.
    @State private var deleteFailed = false

    private var filteredRecipes: [Recipe] {
        filter.apply(to: allRecipes, searchText: searchText)
    }

    var body: some View {
        NavigationStack {
            content
                .screenBackground()
                .navigationTitle("Rezepte")
                .searchable(text: $searchText, prompt: "Titel, Zutat, Tag oder Notiz")
                .toolbar { toolbarContent }
                .navigationDestination(for: Recipe.self) { recipe in
                    RecipeDetailView(recipe: recipe)
                }
                .sheet(isPresented: $showFilterSheet) {
                    RecipeFilterSheet(filter: $filter)
                }
                .sheet(isPresented: $showNewRecipeEditor) {
                    RecipeEditorView(recipe: nil)
                }
                .sheet(item: $recipeToEdit) { recipe in
                    RecipeEditorView(recipe: recipe)
                }
                .confirmationDialog(
                    "Rezept löschen?",
                    isPresented: Binding(
                        get: { recipeToDelete != nil },
                        set: { if !$0 { recipeToDelete = nil } }
                    ),
                    titleVisibility: .visible
                ) {
                    Button("„\(recipeToDelete?.title ?? "")“ löschen", role: .destructive) {
                        if let recipe = recipeToDelete,
                           !RecipeImportService.delete(recipe, in: modelContext) {
                            deleteFailed = true
                        }
                        recipeToDelete = nil
                    }
                    Button("Abbrechen", role: .cancel) {
                        recipeToDelete = nil
                    }
                }
                .saveErrorAlert($deleteFailed)
        }
    }

    // MARK: Inhalt

    @ViewBuilder
    private var content: some View {
        if allRecipes.isEmpty {
            EmptyStateView(
                icon: "book.closed",
                title: "Noch keine Rezepte",
                message: "Lege dein erstes Rezept an — oder importiere eines aus Foto, PDF oder Web.",
                actionTitle: "Neues Rezept",
                action: { showNewRecipeEditor = true }
            )
        } else if filteredRecipes.isEmpty {
            EmptyStateView(
                icon: "line.3.horizontal.decrease.circle",
                title: "Keine Treffer",
                message: "Mit den aktuellen Filtern bzw. der Suche wurde nichts gefunden.",
                actionTitle: filter.isActive ? "Filter zurücksetzen" : nil,
                action: filter.isActive ? { filter.reset() } : nil
            )
        } else {
            ScrollView {
                if horizontalSizeClass == .compact {
                    // iPhone: großzügige Kartenliste.
                    LazyVStack(spacing: AppSpacing.m) {
                        ForEach(filteredRecipes) { recipe in
                            recipeLink(recipe) {
                                RecipeCardView(recipe: recipe)
                            }
                        }
                    }
                    .padding(.horizontal, AppSpacing.screen)
                    .padding(.vertical, AppSpacing.l)
                } else {
                    // iPad: Grid mit kompakten Karten.
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 260), spacing: AppSpacing.l)],
                        spacing: AppSpacing.l
                    ) {
                        ForEach(filteredRecipes) { recipe in
                            recipeLink(recipe) {
                                RecipeGridCardView(recipe: recipe)
                            }
                        }
                    }
                    .padding(AppSpacing.screen)
                }
            }
        }
    }

    /// Karte mit Navigation und Kontextmenü (Favorit, Bearbeiten, Löschen).
    private func recipeLink<Card: View>(_ recipe: Recipe, @ViewBuilder card: () -> Card) -> some View {
        NavigationLink(value: recipe) {
            card()
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                recipe.isFavorite.toggle()
                try? modelContext.save()
            } label: {
                Label(
                    recipe.isFavorite ? "Favorit entfernen" : "Als Favorit markieren",
                    systemImage: recipe.isFavorite ? "heart.slash" : "heart"
                )
            }
            Button {
                recipeToEdit = recipe
            } label: {
                Label("Bearbeiten", systemImage: "pencil")
            }
            Button(role: .destructive) {
                recipeToDelete = recipe
            } label: {
                Label("Löschen", systemImage: "trash")
            }
        }
    }

    // MARK: Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Menu {
                Picker("Sortierung", selection: $filter.sortOrder) {
                    ForEach(RecipeFilter.SortOrder.allCases) { order in
                        Text(order.label).tag(order)
                    }
                }
            } label: {
                Label("Sortierung", systemImage: "arrow.up.arrow.down")
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showFilterSheet = true
            } label: {
                Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
            }
            .overlay(alignment: .topTrailing) {
                if filter.isActive {
                    Text("\(filter.activeCount)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(4)
                        .background(AppColors.copper, in: Circle())
                        .offset(x: 6, y: -6)
                }
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showNewRecipeEditor = true
            } label: {
                Label("Neues Rezept", systemImage: "plus")
            }
        }
    }
}

#Preview {
    RecipeListView()
        .modelContainer(PreviewSupport.container)
}
