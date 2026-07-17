import Foundation
import SwiftData

/// Tauscht einzelne Rezepte als `.rezeptwerk`-Datei — z. B. per WhatsApp,
/// Mail oder als Forum-Anhang. Wer die Datei antippt und RezeptWerk
/// installiert hat, bekommt das Rezept direkt als Editor-Vorschau.
///
/// Das Dateiformat ist bewusst das bewährte Backup-Format
/// (`BackupDocument` mit genau einem Rezept) — stabil, versioniert und
/// inklusive Bildern, Schritt-Fotos und Wurst-Fachdaten.
@MainActor
enum RecipeShareService {

    /// Die Dateiendung des Tausch-Formats.
    static let fileExtension = "rezeptwerk"

    enum ShareError: LocalizedError {
        case invalidFile

        var errorDescription: String? {
            "Die Datei ist keine gültige RezeptWerk-Datei oder beschädigt."
        }
    }

    /// Schreibt das Rezept als Tausch-Datei ins Temp-Verzeichnis und gibt
    /// die URL zurück (für `ShareLink`).
    ///
    /// **Persönliches bleibt privat:** Bewertung, Favoriten-Herz,
    /// „zuletzt gekocht“ und die eigenen Koch-Notizen werden vor dem
    /// Teilen entfernt — geteilt wird nur das Rezept selbst.
    static func makeShareFile(for recipe: Recipe) throws -> URL {
        var backup = BackupService.backup(from: recipe)
        backup.rating = 0
        backup.isFavorite = false
        backup.lastCookedAt = nil
        backup.cookingNotes = nil

        let appVersion = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? "?"
        let document = BackupDocument(
            appVersion: appVersion,
            exportedAt: .now,
            recipes: [backup]
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        let data = try encoder.encode(document)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(RecipeExportService.sanitizedFileName(recipe.title))
            .appendingPathExtension(fileExtension)
        try data.write(to: url, options: .atomic)
        return url
    }

    /// Liest eine geöffnete `.rezeptwerk`-Datei und gibt das enthaltene
    /// Rezept (als Backup-DTO) zurück.
    static func loadRecipe(from url: URL) throws -> RecipeBackup {
        // Dateien aus anderen Apps können hinter einer Sicherheits-Schranke
        // liegen — Zugriff anmelden und danach wieder abmelden.
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }

        guard let data = try? Data(contentsOf: url) else {
            throw ShareError.invalidFile
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let document = try? decoder.decode(BackupDocument.self, from: data),
              let first = document.recipes.first
        else { throw ShareError.invalidFile }

        return first
    }
}
