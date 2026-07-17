import Foundation
import CoreData
import CloudKit
import Observation
import SwiftData

/// Beobachtet den iCloud-Synchronisierungs-Status und macht ihn in den
/// Einstellungen sichtbar.
///
/// Auch wenn die App SwiftData nutzt, läuft darunter ein
/// `NSPersistentCloudKitContainer`. Dieser sendet bei jeder Synchronisierung
/// (Einrichtung, Hochladen, Herunterladen) eine systemweite Mitteilung —
/// genau die hören wir hier ab. Zusätzlich fragen wir, ob das Gerät
/// überhaupt bei iCloud angemeldet ist.
@MainActor
@Observable
final class CloudSyncMonitor {

    /// Geteilte Instanz — beim App-Start gestartet (siehe `RezeptWerkApp`).
    static let shared = CloudSyncMonitor()

    /// iCloud-Konto-Status des Geräts.
    enum AccountState {
        case unknown
        case available      // angemeldet, alles bereit
        case noAccount      // nicht bei iCloud angemeldet
        case unavailable    // eingeschränkt / vorübergehend nicht verfügbar
    }

    private(set) var accountState: AccountState = .unknown
    /// Zeitpunkt der letzten erfolgreichen Synchronisierung.
    private(set) var lastSyncDate: Date?
    /// Läuft gerade eine Synchronisierung?
    private(set) var isSyncing = false
    /// Letzte Fehlermeldung (falls etwas schiefging).
    private(set) var lastErrorMessage: String?

    private var started = false

    /// Zugriff auf die Datenbank — nötig, um nach einem Import Duplikate
    /// aufzuräumen (siehe `DeduplicationService`).
    private var container: ModelContainer?

    private init() {}

    /// Beginnt mit dem Beobachten (idempotent — mehrfacher Aufruf schadet nicht).
    func start(container: ModelContainer) {
        self.container = container
        guard !started else { return }
        started = true

        NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil,
            queue: .main
        ) { notification in
            guard let event = notification.userInfo?[
                NSPersistentCloudKitContainer.eventNotificationUserInfoKey
            ] as? NSPersistentCloudKitContainer.Event else { return }
            // Sicher auf den MainActor zurückspringen.
            Task { @MainActor in
                CloudSyncMonitor.shared.handle(event)
            }
        }

        Task { await refreshAccountStatus() }
    }

    /// Fragt beim System nach, ob ein iCloud-Konto verfügbar ist.
    func refreshAccountStatus() async {
        do {
            let status = try await CKContainer(
                identifier: ModelContainerFactory.cloudContainerID
            ).accountStatus()

            switch status {
            case .available:
                accountState = .available
            case .noAccount:
                accountState = .noAccount
            default:
                accountState = .unavailable
            }
        } catch {
            // Kein gültiger Container (z. B. Capability noch nicht aktiviert).
            accountState = .unavailable
        }
    }

    // MARK: Ereignisse auswerten

    private func handle(_ event: NSPersistentCloudKitContainer.Event) {
        if event.endDate == nil {
            // Vorgang hat gerade begonnen.
            isSyncing = true
            lastErrorMessage = nil
        } else {
            // Vorgang abgeschlossen.
            isSyncing = false
            if event.succeeded {
                lastSyncDate = event.endDate
                lastErrorMessage = nil

                // Nach jedem erfolgreichen Herunterladen aus der Cloud:
                // eventuell mitgekommene Duplikate (Kategorien,
                // Beispielrezepte …) sofort wieder zusammenführen.
                if event.type == .import, let container {
                    DeduplicationService.run(context: container.mainContext)
                }
            } else if let error = event.error {
                lastErrorMessage = error.localizedDescription
            }
        }
    }
}
