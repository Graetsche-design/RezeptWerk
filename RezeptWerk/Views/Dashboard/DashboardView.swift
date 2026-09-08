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
            .screenBackground(glowAt: .topTrailing)
            .navigationTitle("RezeptWerk")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Rezepte durchsuchen …")
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(recipe: recipe)
            }
            // Aus dem Wochenplan: Detailansicht mit den geplanten Portionen.
            .navigationDestination(for: PlannedMeal.self) { meal in
                if let recipe = meal.recipe {
                    RecipeDetailView(recipe: recipe, initialServings: meal.effectiveServings)
                }
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

                forumCard
                    .padding(.horizontal, AppSpacing.screen)
            }
            .padding(.top, AppSpacing.l)
            .padding(.bottom, AppSpacing.xxl)
        }
    }

    /// Einstieg in den Wochenplan — zeigt die heute geplanten Mahlzeiten.
    /// (Das `navigationDestination(for: Recipe.self)` des Dashboard-Stacks
    /// gilt auch hier — keine eigene Registrierung nötig.)
    private var plannerCard: some View {
        NavigationLink {
            WeekPlannerView()
        } label: {
            HStack(spacing: AppSpacing.m) {
                IconBadge(systemName: "calendar")

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

    /// Einstieg in die Einkaufsliste — zeigt die Anzahl offener Einträge,
    /// bei offenen Einträgen als Kupfer-Plakette.
    private var shoppingListCard: some View {
        let openCount = shoppingItems.filter { !$0.isChecked }.count
        return NavigationLink {
            ShoppingListView()
        } label: {
            HStack(spacing: AppSpacing.m) {
                IconBadge(systemName: "cart")

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

                if openCount > 0 {
                    Text("\(openCount)")
                        .font(AppTypography.caption.weight(.bold))
                        .foregroundStyle(AppColors.backgroundPrimary)
                        .padding(.horizontal, AppSpacing.s + 2)
                        .frame(minWidth: 28, minHeight: 28)
                        .background(AppColors.copper, in: Capsule())
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColors.textSecondary.opacity(0.6))
                }
            }
            .card(padding: AppSpacing.l)
        }
        .buttonStyle(.plain)
    }

    /// Der Werkzeuge-Bereich als kompaktes Raster — jedes Werkzeug mit
    /// eigenem Farbton.
    private var toolsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            SectionHeaderView(title: "Werkzeuge")

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: AppSpacing.m), GridItem(.flexible(), spacing: AppSpacing.m)],
                spacing: AppSpacing.m
            ) {
                toolTile(
                    // Weiche Trennstelle: In der schmalen Kachel darf das
                    // Wort als „Kern-temperaturen“ umbrechen.
                    title: "Kern\u{00AD}temperaturen",
                    subtitle: "Nachschlagen",
                    icon: "thermometer.medium",
                    tint: AppColors.coral
                ) {
                    KerntemperaturView()
                }

                toolTile(
                    title: "Wurst-Rechner",
                    subtitle: "Zutaten je kg",
                    icon: "scalemass",
                    tint: AppColors.tan
                ) {
                    WurstRechnerView()
                }

                toolTile(
                    title: "Pökel-Rechner",
                    subtitle: "Lake & Pökelzeit",
                    icon: "drop.fill",
                    tint: AppColors.sky
                ) {
                    PoekelRechnerView()
                }

                toolTile(
                    title: "Umrechner",
                    subtitle: "Cups, Unzen, °F",
                    icon: "arrow.left.arrow.right",
                    tint: AppColors.teal
                ) {
                    UmrechnerView()
                }
            }
        }
    }

    /// Eine Werkzeug-Kachel: getöntes Symbol-Quadrat, Titel, Untertitel.
    private func toolTile<Destination: View>(
        title: String,
        subtitle: String,
        icon: String,
        tint: Color,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: AppSpacing.s + 2) {
                IconBadge(systemName: icon, size: 38, tint: tint, cornerRadius: AppRadius.small)

                VStack(alignment: .leading, spacing: 2) {
                    // Die Kachel ist schmal: lange Namen dürfen auf zwei
                    // Zeilen gehen und notfalls leicht schrumpfen.
                    Text(title)
                        .font(AppTypography.secondary.weight(.semibold))
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .multilineTextAlignment(.leading)

                    Text(subtitle)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .card(padding: AppSpacing.m)
        }
        .buttonStyle(.plain)
    }

    /// Absprung zum Forum „Kochen mit ReiMa“ — als Ausklang des Dashboards
    /// (gleicher Bauplan wie die übrigen Karten; der Pfeil nach außen
    /// zeigt: hier öffnet sich der Browser).
    private var forumCard: some View {
        Group {
            if let url = URL(string: "https://kochenmitreima.de") {
                Link(destination: url) {
                    HStack(spacing: AppSpacing.m) {
                        IconBadge(systemName: "globe")

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Kochen mit ReiMa")
                                .font(AppTypography.cardTitle)
                                .foregroundStyle(AppColors.textPrimary)

                            Text("Unser Forum: Rezepte & Küchenwissen")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColors.textSecondary)
                        }

                        Spacer(minLength: 0)

                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppColors.textSecondary.opacity(0.6))
                    }
                    .card(padding: AppSpacing.l)
                }
                .buttonStyle(.plain)
            }
        }
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
