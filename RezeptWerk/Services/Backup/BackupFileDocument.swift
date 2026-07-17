import SwiftUI
import UniformTypeIdentifiers

/// Verpackt die Backup-Daten für den System-Dialog „In Dateien sichern“
/// (`fileExporter`). Über diesen Dialog landet das Backup z. B. in
/// Google Drive, iCloud Drive oder Dropbox.
struct BackupFileDocument: FileDocument {

    /// Backups sind JSON-Dateien.
    static var readableContentTypes: [UTType] { [.json] }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
