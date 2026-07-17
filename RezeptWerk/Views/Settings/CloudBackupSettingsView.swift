import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// Einstellungs-Abschnitte für iCloud-Synchronisierung und Backup.
///
/// Wird in `SettingsView` eingebettet. Hält die nötigen Zustände für die
/// Datei-Dialoge selbst, damit `SettingsView` schlank bleibt.
struct CloudBackupSettingsView: View {

    @AppStorage(SettingsKeys.iCloudSync) private var iCloudSync = false
    @Environment(\.modelContext) private var modelContext

    // iCloud
    @State private var showRestartHint = false
    @State private var syncMonitor = CloudSyncMonitor.shared

    // Backup erstellen
    @State private var backupDocument: BackupFileDocument?
    @State private var showExporter = false

    // Backup wiederherstellen
    @State private var showImporter = false
    @State private var pendingRestoreData: Data?
    @State private var showRestoreOptions = false

    // Ergebnis-/Fehlermeldungen
    @State private var resultMessage: String?
    @State private var backupError: BackupError?

    var body: some View {
        iCloudSection
        backupSection
    }

    // MARK: iCloud

    private var iCloudSection: some View {
        Section {
            Toggle("Mit iCloud synchronisieren", isOn: $iCloudSync)
                .tint(AppColors.copper)
                .onChange(of: iCloudSync) {
                    showRestartHint = true
                }

            if iCloudSync {
                syncStatusRow
            }
        } header: {
            Text("iCloud-Synchronisierung")
        } footer: {
            Text("Hält deine Rezepte automatisch über alle deine Geräte mit derselben Apple-ID synchron. Dafür musst du auf dem Gerät bei iCloud angemeldet sein. Änderungen erscheinen nach einem Neustart der App.")
        }
        .alert("Bitte App neu starten", isPresented: $showRestartHint) {
            Button("Verstanden", role: .cancel) {}
        } message: {
            Text("Die geänderte iCloud-Einstellung wird beim nächsten Start der App wirksam.")
        }
        .task {
            await syncMonitor.refreshAccountStatus()
        }
    }

    /// Zeigt sichtbar an, ob und wann zuletzt synchronisiert wurde.
    private var syncStatusRow: some View {
        HStack(spacing: AppSpacing.m) {
            Image(systemName: status.icon)
                .font(.system(size: 20))
                .foregroundStyle(status.isProblem ? .orange : AppColors.copper)
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 2) {
                Text(status.title)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textPrimary)
                if let detail = status.detail {
                    Text(detail)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }

            Spacer()

            if syncMonitor.isSyncing {
                ProgressView()
            }
        }
        .padding(.vertical, 2)
    }

    /// Übersetzt den Monitor-Zustand in eine verständliche Anzeige.
    private var status: (icon: String, title: String, detail: String?, isProblem: Bool) {
        if syncMonitor.accountState == .noAccount {
            return ("exclamationmark.icloud",
                    "Nicht bei iCloud angemeldet",
                    "Melde dich in den iPhone-Einstellungen oben bei deiner Apple-ID an.",
                    true)
        }
        if let error = syncMonitor.lastErrorMessage {
            return ("exclamationmark.icloud", "Synchronisierung gestört", error, true)
        }
        if syncMonitor.isSyncing {
            return ("arrow.triangle.2.circlepath.icloud", "Synchronisiert gerade …", nil, false)
        }
        if let date = syncMonitor.lastSyncDate {
            return ("checkmark.icloud",
                    "Synchronisiert",
                    "Zuletzt \(FormatHelpers.relativeDate(date))",
                    false)
        }
        return ("icloud",
                "Warte auf erste Synchronisierung",
                "Sobald sich etwas ändert, wird automatisch synchronisiert.",
                false)
    }

    // MARK: Backup

    private var backupSection: some View {
        Section {
            Button {
                createBackup()
            } label: {
                Label("Backup erstellen", systemImage: "square.and.arrow.up.on.square")
            }
            .foregroundStyle(AppColors.copper)

            Button {
                showImporter = true
            } label: {
                Label("Backup wiederherstellen", systemImage: "square.and.arrow.down.on.square")
            }
            .foregroundStyle(AppColors.copper)
        } header: {
            Text("Backup (Google Drive, Dropbox …)")
        } footer: {
            Text("„Backup erstellen“ speichert alle Rezepte als eine Datei — sichere sie über die Dateien-App in Google Drive, iCloud Drive oder Dropbox. „Wiederherstellen“ liest so eine Datei wieder ein.")
        }
        // Export-Dialog („In Dateien sichern“ → Google Drive).
        .fileExporter(
            isPresented: $showExporter,
            document: backupDocument,
            contentType: .json,
            defaultFilename: BackupService.suggestedFileName()
        ) { result in
            if case .success = result {
                resultMessage = "Dein Backup wurde gespeichert."
            }
        }
        // Import-Dialog.
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.json]
        ) { result in
            handleImportSelection(result)
        }
        // Wahl zwischen Zusammenführen und Ersetzen.
        .confirmationDialog(
            "Backup wiederherstellen",
            isPresented: $showRestoreOptions,
            titleVisibility: .visible
        ) {
            Button("Hinzufügen") { performRestore(mode: .merge) }
            Button("Alles ersetzen", role: .destructive) { performRestore(mode: .replace) }
            Button("Abbrechen", role: .cancel) { pendingRestoreData = nil }
        } message: {
            Text("„Hinzufügen“ ergänzt die Rezepte aus dem Backup. „Alles ersetzen“ löscht zuerst deine aktuellen Rezepte.")
        }
        .alert("Geschafft", isPresented: Binding(
            get: { resultMessage != nil },
            set: { if !$0 { resultMessage = nil } }
        )) {
            Button("Prima", role: .cancel) {}
        } message: {
            Text(resultMessage ?? "")
        }
        .alert(
            "Wiederherstellen nicht möglich",
            isPresented: Binding(
                get: { backupError != nil },
                set: { if !$0 { backupError = nil } }
            )
        ) {
            Button("Verstanden", role: .cancel) {}
        } message: {
            if let backupError {
                Text([backupError.errorDescription, backupError.recoverySuggestion]
                    .compactMap(\.self)
                    .joined(separator: "\n\n"))
            }
        }
    }

    // MARK: Aktionen

    private func createBackup() {
        do {
            let data = try BackupService.makeBackupData(context: modelContext)
            backupDocument = BackupFileDocument(data: data)
            showExporter = true
        } catch {
            backupError = .invalidFile
        }
    }

    private func handleImportSelection(_ result: Result<URL, Error>) {
        guard case .success(let url) = result else { return }

        // Dateien aus dem System-Dialog liegen außerhalb der App-Sandbox.
        let hasAccess = url.startAccessingSecurityScopedResource()
        defer {
            if hasAccess { url.stopAccessingSecurityScopedResource() }
        }

        guard let data = try? Data(contentsOf: url) else {
            backupError = .invalidFile
            return
        }
        pendingRestoreData = data
        showRestoreOptions = true
    }

    private func performRestore(mode: BackupService.RestoreMode) {
        guard let data = pendingRestoreData else { return }
        pendingRestoreData = nil
        do {
            let count = try BackupService.restore(from: data, mode: mode, context: modelContext)
            resultMessage = count == 1
                ? "1 Rezept wiederhergestellt."
                : "\(count) Rezepte wiederhergestellt."
        } catch let error as BackupError {
            backupError = error
        } catch {
            backupError = .invalidFile
        }
    }
}
