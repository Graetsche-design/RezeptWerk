import CoreSpotlight
import SwiftUI
import UIKit

/// Die Hauptnavigation der App.
///
/// Ein einziges `TabView` mit `.sidebarAdaptable`:
/// - **iPhone**: klassische Tab-Leiste mit genau fünf Tabs
///   („Kategorien“ ist dort über das Dashboard erreichbar).
/// - **iPad**: komfortable Sidebar mit allen sechs Bereichen.
struct RootView: View {

    @State private var selectedTab: AppTab = .dashboard

    /// Über die Teilen-Erweiterung geteilter Inhalt, der gerade verarbeitet
    /// wird (steuert das Import-Sheet).
    @State private var sharedImport: SharedImportInbox.Pending?

    /// Meldung des Entwicklers an alle Nutzer (z. B. Update-Hinweis), die
    /// als Banner über der App erscheint. Wird beim Start vom Server
    /// geladen — siehe `AnnouncementService`.
    @State private var announcement: Announcement?

    /// Über eine geöffnete `.rezeptwerk`-Datei empfangenes Rezept
    /// (steuert das Editor-Sheet des Rezept-Tauschs).
    @State private var receivedRecipe: ReceivedRecipeFile?

    /// Zeigt den Hinweis, wenn eine geöffnete Datei nicht lesbar war.
    @State private var showFileError = false

    /// Über die iOS-Suche (Spotlight) angetipptes Rezept (steuert das
    /// Detail-Sheet).
    @State private var spotlightRecipe: Recipe?

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext

    @AppStorage(SettingsKeys.keepScreenOn)
    private var keepScreenOn = false

    /// Geräteklasse statt Size-Class: bleibt beim Drehen stabil, sodass
    /// die Tab-Leiste auf dem iPhone nie in den „Mehr“-Überlauf rutscht.
    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Start", systemImage: "house.fill", value: AppTab.dashboard) {
                DashboardView()
            }

            Tab("Rezepte", systemImage: "book.closed.fill", value: AppTab.recipes) {
                RecipeListView()
            }

            // Wochenplan und Kategorien bekommen nur auf dem iPad einen
            // eigenen Sidebar-Eintrag — auf dem iPhone sind sie über das
            // Dashboard erreichbar (mehr als fünf Tabs würden im „Mehr“-Menü
            // verschwinden).
            if isPad {
                Tab("Wochenplan", systemImage: "calendar", value: AppTab.planner) {
                    NavigationStack {
                        WeekPlannerView()
                            .navigationDestination(for: Recipe.self) { recipe in
                                RecipeDetailView(recipe: recipe)
                            }
                            // Geplantes Gericht → Detailansicht mit den
                            // geplanten Portionen.
                            .navigationDestination(for: PlannedMeal.self) { meal in
                                if let recipe = meal.recipe {
                                    RecipeDetailView(recipe: recipe, initialServings: meal.effectiveServings)
                                }
                            }
                    }
                }

                Tab("Einkaufsliste", systemImage: "cart", value: AppTab.shoppingList) {
                    NavigationStack {
                        ShoppingListView()
                    }
                }

                Tab("Kategorien", systemImage: "square.grid.2x2.fill", value: AppTab.categories) {
                    CategoriesView()
                }
            }

            Tab("Favoriten", systemImage: "heart.fill", value: AppTab.favorites) {
                FavoritesView()
            }

            Tab("Importieren", systemImage: "square.and.arrow.down.fill", value: AppTab.importHub) {
                ImportHubView()
            }

            Tab("Einstellungen", systemImage: "gearshape.fill", value: AppTab.settings) {
                SettingsView()
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .tint(AppColors.copper)
        // Design „Dunkle Glut“: Die App ist immer dunkel — so passen auch
        // System-Elemente (Blätter, Listen, Tastatur) zum Räucherholz-Grund.
        .preferredColorScheme(.dark)
        .environment(\.switchTab, TabSwitchAction(switchTo: { selectedTab = $0 }))
        // Hinweisfenster für Meldungen des Entwicklers (z. B. Update-Hinweis).
        .overlay {
            if let announcement {
                AnnouncementOverlayView(announcement: announcement) {
                    AnnouncementService.markDismissed(announcement)
                    withAnimation(.easeOut(duration: 0.25)) {
                        self.announcement = nil
                    }
                }
                .transition(.opacity)
            }
        }
        .task {
            // Einmal pro Start nachsehen, ob eine Meldung vorliegt.
            guard let pending = await AnnouncementService.fetchPending() else { return }
            withAnimation(.spring(duration: 0.35)) {
                announcement = pending
            }
        }
        // Über die Teilen-Erweiterung geteilte Rezepte aufgreifen — und den
        // Widget-Schnappschuss auffrischen (fängt auch Plan-Änderungen ab,
        // die nicht über den Wochenplaner laufen, z. B. gelöschte Rezepte,
        // Backup-Wiederherstellung oder iCloud-Änderungen).
        .onAppear {
            checkSharedInbox()
            WidgetPlanSync.refresh(context: modelContext)
            applyKeepScreenOn()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                checkSharedInbox()
                WidgetPlanSync.refresh(context: modelContext)
                applyKeepScreenOn()
            }
        }
        // Greift sofort, wenn der Schalter in den Einstellungen umgelegt wird.
        .onChange(of: keepScreenOn) { _, _ in
            applyKeepScreenOn()
        }
        .sheet(item: $sharedImport) { pending in
            SharedImportView(pending: pending)
        }
        // Rezept-Tausch: Eine angetippte .rezeptwerk-Datei landet hier.
        .onOpenURL { url in
            guard url.pathExtension.lowercased() == RecipeShareService.fileExtension else { return }
            do {
                let backup = try RecipeShareService.loadRecipe(from: url)
                // Den Editor-Entwurf genau EINMAL hier bauen — nicht im
                // Sheet-Inhalt, der bei jedem Neuzeichnen erneut liefe.
                receivedRecipe = ReceivedRecipeFile(
                    draft: RecipeDraft(backup: backup, context: modelContext)
                )
            } catch {
                showFileError = true
            }
        }
        .sheet(item: $receivedRecipe) { received in
            // Der Editor ist die Vorschau: alles prüfen, anpassen, speichern.
            RecipeEditorView(recipe: nil, prefilledDraft: received.draft)
        }
        .alert("Datei konnte nicht gelesen werden", isPresented: $showFileError) {
            Button("Verstanden", role: .cancel) {}
        } message: {
            Text("Die Datei ist keine gültige RezeptWerk-Datei oder beschädigt.")
        }
        // Spotlight: Ein angetippter Suchtreffer öffnet das Rezept.
        .onContinueUserActivity(CSSearchableItemActionType) { activity in
            guard let identifier = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String,
                  let recipe = SpotlightIndexService.recipe(
                    forSpotlightIdentifier: identifier,
                    context: modelContext
                  )
            else { return }
            spotlightRecipe = recipe
        }
        .sheet(item: $spotlightRecipe) { recipe in
            NavigationStack {
                RecipeDetailView(recipe: recipe)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Fertig") { spotlightRecipe = nil }
                        }
                    }
            }
        }
    }

    /// Hält den Bildschirm wach, wenn die Einstellung „Bildschirm immer an“
    /// aktiv ist (dritte bewusste UIKit-Stelle der App — SwiftUI bietet
    /// dafür keine eigene API).
    private func applyKeepScreenOn() {
        UIApplication.shared.isIdleTimerDisabled = keepScreenOn
    }

    /// Prüft, ob die Teilen-Erweiterung etwas hinterlegt hat, und startet
    /// die Verarbeitung. Wird beim Start und bei jeder Aktivierung aufgerufen.
    private func checkSharedInbox() {
        // Nur prüfen, wenn nicht schon ein geteilter Import läuft.
        guard sharedImport == nil, let pending = SharedImportInbox.take() else { return }
        sharedImport = pending
    }
}

/// Hülle um den fertigen Editor-Entwurf eines empfangenen Rezepts, damit
/// `sheet(item:)` ihn anzeigen kann.
private struct ReceivedRecipeFile: Identifiable {
    let id = UUID()
    let draft: RecipeDraft
}

#Preview {
    RootView()
        .modelContainer(PreviewSupport.container)
}
