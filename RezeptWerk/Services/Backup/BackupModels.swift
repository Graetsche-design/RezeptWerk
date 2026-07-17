import Foundation

/// Übertragbare (Codable) Abbilder der Rezeptdaten für Backup & Export.
///
/// Bewusst **getrennt** von den SwiftData-Modellen: Die `@Model`-Klassen
/// lassen sich nicht direkt als JSON speichern. Diese schlichten Structs
/// sind das stabile Dateiformat — sie können auch in künftigen Versionen
/// gelesen werden (`formatVersion`).
struct BackupDocument: Codable {
    /// Version des Dateiformats — erlaubt später sanfte Migrationen.
    var formatVersion: Int = 1
    /// App-Version, mit der das Backup erstellt wurde (nur zur Info).
    var appVersion: String
    var exportedAt: Date
    var recipes: [RecipeBackup]
}

struct RecipeBackup: Codable {
    var title: String
    var servings: Int
    var prepMinutes: Int?
    var cookMinutes: Int?
    var restMinutes: Int?
    var difficultyRaw: Int
    var rating: Int
    var isFavorite: Bool
    /// Mahlzeit-Eignung als Bitmaske. Optional, damit ältere Backups (ohne
    /// dieses Feld) weiterhin gelesen werden können.
    var mealTypeMask: Int?
    var notes: String
    var sourceText: String
    var sourceURLString: String
    var createdAt: Date
    var updatedAt: Date
    var lastCookedAt: Date?

    /// Kategorie/Unterkategorie werden über den Namen gesichert und beim
    /// Import wiederverwendet oder neu angelegt.
    var categoryName: String?
    var categoryIcon: String?
    var subcategoryName: String?

    var tags: [String]
    var ingredients: [IngredientBackup]
    var steps: [StepBackup]
    /// Bilder als Base64 — so ist das Backup eine einzige, vollständige Datei.
    var imagesBase64: [String]
    var sausage: SausageBackup?
    /// Datierte Koch-Notizen. Optional, damit ältere Backups (ohne dieses
    /// Feld) weiterhin gelesen werden können.
    var cookingNotes: [CookingNoteBackup]?
}

struct CookingNoteBackup: Codable {
    var date: Date
    var text: String
}

struct IngredientBackup: Codable {
    var amount: Double?
    var unit: String
    var name: String
}

struct StepBackup: Codable {
    var text: String
    var timerSeconds: Int?
}

struct SausageBackup: Codable {
    var meatWeightKg: Double?
    var seasoningPerKg: String
    var npsGramsPerKg: Double?
    var cutterAids: String
    var iceWaterPercent: Double?
    var casing: String
    var smokingMethodRaw: String
    var smokingTimeMinutes: Int?
    var smokingTemperatureCelsius: Int?
    var scaldingTemperatureCelsius: Int?
    var coreTemperatureCelsius: Int?
    var curingDays: Int?
    var dryingDays: Int?
    var safetyNotes: String
}
