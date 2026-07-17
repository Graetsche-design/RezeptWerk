import SwiftUI
import SwiftData

/// Die Startseite: Begrüßung, Schnellzugriffe, Favoriten, zuletzt
/// hinzugefügte Rezepte und die Kategorienübersicht.
///
/// Die Suche oben durchsucht den ganzen Rezeptbestand — bei aktiver
/// Suche werden statt des Dashboards die Treffer angezeigt.
struct DashboardView: View {

    @Query(sort: \Recipe.createdAt, order: .reverse)
    private var allRecipes: [Recipe]

    @Query(sort: \RecipeCategory.sortIndex)
    private var categories: [RecipeCategory]

    @Query private var plannedMeals: [PlannedMeal]

    @Query private var shoppingItems: [ShoppingItem]

    @Environment(\.switchTab) private var switchTab
    @State private var searchText = ""
    @State private var showNewRecipeEditor = false

    /// Heute geplante Mahlzeiten, nach Mahlzeit-Typ sortiert.
    private var todaysMeals: [PlannedMeal] {
        plannedMeals
            .filter { Calendar.current.isDateInToday($0.date) }
            .sorted { $0.mealType.sortOrder < $1.mealType.sortOrder }
    }

    private var favorites: [Recipe] {
        allRecipes.filter(\.isFavorite)
    }

    private var recentRecipes: [Recipe] {
        Array(allRecipes.prefix(8))
    }

    /// Suchtreffer über den kompletten Bestand (Titel, Zutaten, Tags, Notizen).
    private var searchResults: [Recipe] {
        RecipeFilter().apply(to: allRecipes, searchText: searchText)
    }

    private var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Group {
                if isSearching {
                    searchResultsList
                } else {
                    dashboardContent
                }
            }
            .screenBackground()
            .navigationTitle("RezeptWerk")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Rezepte durchsuchen …")
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(recipe: recipe)
            }
            .navigationDestination(for: RecipeCategory.self) { category in
                CategoryRecipesView(category: category)
            }
            .sheet(isPresented: $showNewRecipeEditor) {
                RecipeEditorView(recipe: nil)
            }
        }
    }

    // MARK: Dashboard-Inhalt

    private var dashboardContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                Group {
                    DashboardGreetingHeader()

                    QuickActionButtons(
                        onNewRecipe: { showNewRecipeEditor = true },
                        onImport: { switchTab(.importHub) }
                    )

                    plannerCard
                    shoppingListCard
                    toolsSection
                }
                .padding(.horizontal, AppSpacing.screen)

                if !favorites.isEmpty {
                    RecipeCarouselSection(
                        title: "Favoriten",
                        recipes: Array(favorites.prefix(8)),
                        seeAllTitle: "Alle",
                        seeAllAction: { switchTab(.favorites) }
                    )
                }

                if !recentRecipes.isEmpty {
                    RecipeCarouselSection(
                        title: "Zuletzt hinzugefügt",
                        recipes: recentRecipes
                    )
                }

                categoriesSection
                    .padding(.horizontal, AppSpacing.screen)
            }
            .padding(.top, AppSpacing.l)
            .padding(.bottom, AppSpacing.xxl)
        }
    }

    /// Einstieg in den Wochenplan — zeigt die heute geplanten Mahlzeiten.
    private var plannerCard: some View {
        NavigationLink {
            WeekPlannerView()
                .navigationDestination(for: Recipe.self) { recipe in
                    RecipeDetailView(recipe: recipe)
                }
        } label: {
            HStack(spacing: AppSpacing.m) {
                Image(systemName: "calendar")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(AppColors.copperGradient, in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("Wochenplan")
                        .font(AppTypography.cardTitle)
                        .foregroundStyle(AppColors.textPrimary)

                    if todaysMeals.isEmpty {
                        Text("Plane deine Woche")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    } else {
                        Text("Heute: " + todaysMeals.compactMap { $0.recipe?.title }.joined(separator: ", "))
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.textSecondary.opacity(0.6))
            }
            .card(padding: AppSpacing.l)
        }
        .buttonStyle(.plain)
    }

    /// Einstieg in die Einkaufsliste — zeigt die Anzahl offener Einträge.
    private var shoppingListCard: some View {
        let openCount = shoppingItems.filter { !$0.isChecked }.count
        return NavigationLink {
            ShoppingListView()
        } label: {
            HStack(spacing: AppSpacing.m) {
                Image(systemName: "cart")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(AppColors.copperGradient, in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("Einkaufsliste")
                        .font(AppTypography.cardTitle)
                        .foregroundStyle(AppColors.textPrimary)

                    Text(openCount == 0
                         ? "Zutaten sammeln"
                         : (openCount == 1 ? "1 offener Eintrag" : "\(openCount) offene Einträge"))
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.textSecondary.opacity(0.6))
            }
            .card(padding: AppSpacing.l)
        }
        .buttonStyle(.plain)
    }

    /// Der Werkzeuge-Bereich: Kerntemperatur-Spickzettel und Wurst-Rechner.
    private var toolsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            SectionHeaderView(title: "Werkzeuge")

            toolCard(
                title: "Kerntemperaturen",
                subtitle: "Gar-Temperaturen zum Nachschlagen",
                icon: "thermometer.medium"
            ) {
                KerntemperaturView()
            }

            toolCard(
                title: "Wurst-Rechner",
                subtitle: "Zutaten je kg hochrechnen",
                icon: "scalemass"
            ) {
                WurstRechnerView()
            }
        }
    }

    /// Eine Werkzeug-Karte (gleicher Bauplan wie Wochenplan/Einkaufsliste).
    private func toolCard<Destination: View>(
        title: String,
        subtitle: String,
        icon: String,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: AppSpacing.m) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(AppColors.copperGradient, in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppTypography.cardTitle)
                        .foregroundStyle(AppColors.textPrimary)

                    Text(subtitle)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.textSecondary.opacity(0.6))
            }
            .card(padding: AppSpacing.l)
        }
        .buttonStyle(.plain)
    }

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            SectionHeaderView(title: "Kategorien")

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 170), spacing: AppSpacing.m)],
                spacing: AppSpacing.m
            ) {
                ForEach(categories) { category in
                    NavigationLink(value: category) {
                        CategoryTileView(category: category)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Suchtreffer

    private var searchResultsList: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.m) {
                if searchResults.isEmpty {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "Keine Treffer",
                        message: "Zu „\(searchText)“ wurde nichts gefunden. Die Suche prüft Titel, Zutaten, Tags und Notizen."
                    )
                } else {
                    ForEach(searchResults) { recipe in
                        NavigationLink(value: recipe) {
                            RecipeCardView(recipe: recipe)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.screen)
            .padding(.vertical, AppSpacing.l)
        }
    }
}

#Preview {
    DashboardView()
        .modelContainer(PreviewSupport.container)
}
