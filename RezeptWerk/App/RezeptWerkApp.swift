import AppIntents
import SwiftUI
import SwiftData

/// Einstiegspunkt von RezeptWerk.
///
/// Hier passiert dreierlei:
/// 1. Das Designsystem wird global konfiguriert (Serifenschrift in der
///    Navigationsleiste).
/// 2. Der SwiftData-Container wird erstellt — lokal oder mit iCloud-Sync,
///    je nach Einstellung (siehe `ModelContainerFactory`).
/// 3. Beim ersten Start werden Standard-Kategorien und Beispielrezepte
///    angelegt.
@main
struct RezeptWerkApp: App {

    /// Die Datenbank (SwiftData). Lokal — oder mit iCloud synchronisiert,
    /// wenn der Nutzer es in den Einstellungen aktiviert hat.
    private let container: ModelContainer

    init() {
        AppTheme.configureNavigationBarAppearance()

        // iCloud-Schalter aus den Einstellungen lesen (Standard: AUS, damit
        // die App auch ohne aktivierte iCloud-Capability sicher startet).
        let iCloudEnabled = UserDefaults.standard.bool(forKey: SettingsKeys.iCloudSync)
        container = ModelContainerFactory.makeContainer(iCloudEnabled: iCloudEnabled)

        SampleDataService.seedIfNeeded(context: container.mainContext)

        // Duplikate aufräumen, die durch frühere iCloud-Synchronisierungen
        // entstanden sein können (mehrfache Kategorien/Beispielrezepte).
        DeduplicationService.run(context: container.mainContext)

        // Sync-Status ab dem Start beobachten, damit die Einstellungen ihn
        // anzeigen können (nur sinnvoll, wenn iCloud aktiv ist). Der Monitor
        // stößt außerdem nach jedem Cloud-Import das Aufräumen von
        // Duplikaten an.
        if iCloudEnabled {
            CloudSyncMonitor.shared.start(container: container)
        }

        // Siri-Kurzbefehle für den Kochmodus beim System anmelden
        // (siehe `CookingIntents`).
        RezeptWerkShortcuts.updateAppShortcutParameters()
    }

    var body: some Scene {
        WindowGroup {
            // Zeigt kurz den animierten Splashscreen und blendet dann in
            // die App über. Die App-Funktion selbst liegt unverändert in
            // `RootView`.
            LaunchRootView()
        }
        .modelContainer(container)
    }
}
