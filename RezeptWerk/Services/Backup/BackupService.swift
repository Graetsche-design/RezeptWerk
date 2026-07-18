import Foundation
import SwiftData

/// Erstellt und liest Backup-Dateien (JSON).
///
/// Ein Backup enthält **alle** Rezepte mit Bildern, Kategorien, Tags und
/// Fachdaten in einer einzigen Datei. Der Nutzer sichert diese Datei über
/// die Dateien-App z. B. in Google Drive, iCloud Drive oder Dropbox und
/// kann sie dort jederzeit wiederherstellen.
@MainActor
enum BackupService {

    /// Wie beim Wiederherstellen mit vorhandenen Rezepten umgegangen wird.
    enum RestoreMode {
        /// Rezepte aus dem Backup zusätzlich anlegen (nichts wird gelöscht).
        case merge
        /// Vorhandene Rezepte löschen und durch das Backup ersetzen.
        case replace
    }

    // MARK: Export

    /// Erzeugt die Backup-Datei als JSON-Daten.
    static func makeBackupData(context: ModelContext) throws -> Data {
        let recipes = try context.fetch(FetchDescriptor<Recipe>())
        let document = BackupDocument(
            appVersion: appVersion(),
            exportedAt: .now,
            recipes: recipes.map(backup(from:))
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(document)
    }

    /// Vorgeschlagener Dateiname, z. B. „RezeptWerk-Backup-2026-06-13“.
    static func suggestedFileName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "RezeptWerk-Backup-\(formatter.string(from: .now))"
    }

    // MARK: Import

    /// Liest eine Backup-Datei und legt die Rezepte an.
    /// Gibt die Anzahl wiederhergestellter Rezepte zurück.
    @discardableResult
    static func restore(from data: Data, mode: RestoreMode, context: ModelContext) throws -> Int {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let document = try? decoder.decode(BackupDocument.self, from: data) else {
            throw BackupError.invalidFile
        }

        if mode == .replace {
            // Nur Rezepte löschen — Kategorien bleiben erhalten und werden
            // beim Einfügen wiederverwendet.
            let existing = try context.fetch(FetchDescriptor<Recipe>())
            for recipe in existing {
                context.delete(recipe)
            }
        }

        // Kategorien einmal laden und in einem Cache wiederverwenden, damit
        // keine Duplikate entstehen. Gibt es gleichnamige Kategorien (kann
        // durch iCloud-Duplikate kurzzeitig vorkommen), gewinnt einfach die
        // erste — `uniqueKeysWithValues:` würde in dem Fall abstürzen.
        var categoryCache = Dictionary(
            ((try? context.fetch(FetchDescriptor<RecipeCategory>())) ?? [])
                .map { ($0.name, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        for backup in document.recipes {
            insert(backup, into: context, categoryCache: &categoryCache)
        }

        try context.save()
        return document.recipes.count
    }

    // MARK: Recipe → Backup

    /// `internal`, damit der Rezept-Datei-Tausch (`RecipeShareService`)
    /// denselben Konverter nutzen kann.
    static func backup(from recipe: Recipe) -> RecipeBackup {
        RecipeBackup(
            title: recipe.title,
            servings: recipe.servings,
            prepMinutes: recipe.prepMinutes,
            cookMinutes: recipe.cookMinutes,
            restMinutes: recipe.restMinutes,
            difficultyRaw: recipe.difficultyRaw,
            rating: recipe.rating,
            isFavorite: recipe.isFavorite,
            mealTypeMask: recipe.mealTypeMask,
            notes: recipe.notes,
            sourceText: recipe.sourceText,
            sourceURLString: recipe.sourceURLString,
            createdAt: recipe.createdAt,
            updatedAt: recipe.updatedAt,
            lastCookedAt: recipe.lastCookedAt,
            categoryName: recipe.category?.name,
            categoryIcon: recipe.category?.iconName,
            subcategoryName: recipe.subcategory?.name,
            tags: recipe.tagNames,
            ingredients: recipe.sortedIngredients.map {
                IngredientBackup(amount: $0.amount, unit: $0.unit, name: $0.name)
            },
            steps: recipe.sortedSteps.map {
                StepBackup(
                    text: $0.text,
                    timerSeconds: $0.timerSeconds,
                    imageBase64: $0.imageData?.base64EncodedString()
                )
            },
            imagesBase64: recipe.sortedImages.map { $0.data.base64EncodedString() },
            sausage: recipe.sausageDetails.map(backup(from:)),
            cookingNotes: recipe.sortedCookingNotes.map {
                CookingNoteBackup(date: $0.date, text: $0.text)
            }
        )
    }

    private static func backup(from details: SausageSmokingDetails) -> SausageBackup {
        SausageBackup(
            meatWeightKg: details.meatWeightKg,
            seasoningPerKg: details.seasoningPerKg,
            npsGramsPerKg: details.npsGramsPerKg,
            cutterAids: details.cutterAids,
            iceWaterPercent: details.iceWaterPercent,
            casing: details.casing,
            smokingMethodRaw: details.smokingMethodRaw,
            smokingTimeMinutes: details.smokingTimeMinutes,
            smokingTemperatureCelsius: details.smokingTemperatureCelsius,
            scaldingTemperatureCelsius: details.scaldingTemperatureCelsius,
            coreTemperatureCelsius: details.coreTemperatureCelsius,
            curingDays: details.curingDays,
            dryingDays: details.dryingDays,
            safetyNotes: details.safetyNotes
        )
    }

    // MARK: Backup → Recipe

    private static func insert(
        _ backup: RecipeBackup,
        into context: ModelContext,
        categoryCache: inout [String: RecipeCategory]
    ) {
        let recipe = Recipe(title: backup.title)
        context.insert(recipe)

        recipe.servings = backup.servings
        recipe.prepMinutes = backup.prepMinutes
        recipe.cookMinutes = backup.cookMinutes
        recipe.restMinutes = backup.restMinutes
        recipe.difficultyRaw = backup.difficultyRaw
        recipe.rating = backup.rating
        recipe.isFavorite = backup.isFavorite
        recipe.mealTypeMask = backup.mealTypeMask ?? 0
        recipe.notes = backup.notes
        recipe.sourceText = backup.sourceText
        recipe.sourceURLString = backup.sourceURLString
        recipe.createdAt = backup.createdAt
        recipe.updatedAt = backup.updatedAt
        recipe.lastCookedAt = backup.lastCookedAt

        // Kategorie wiederverwenden oder neu anlegen.
        if let categoryName = backup.categoryName {
            let category = resolveCategory(
                name: categoryName,
                icon: backup.categoryIcon ?? "fork.knife",
                cache: &categoryCache,
                context: context
            )
            recipe.category = category

            if let subName = backup.subcategoryName {
                recipe.subcategory = resolveSubcategory(name: subName, in: category, context: context)
            }
        }

        recipe.tags = RecipeImportService.resolveTags(names: backup.tags, in: context)

        recipe.ingredients = backup.ingredients.enumerated().map { index, item in
            Ingredient(amount: item.amount, unit: item.unit, name: item.name, sortIndex: index)
        }
        recipe.steps = backup.steps.enumerated().map { index, item in
            RecipeStep(
                text: item.text,
                sortIndex: index,
                timerSeconds: item.timerSeconds,
                imageData: item.imageBase64.flatMap { Data(base64Encoded: $0) }
            )
        }
        recipe.images = backup.imagesBase64.enumerated().compactMap { index, base64 in
            guard let data = Data(base64Encoded: base64) else { return nil }
            return RecipeImage(data: data, sortIndex: index)
        }

        if let sausage = backup.sausage {
            recipe.sausageDetails = makeDetails(from: sausage)
        }

        // Koch-Notizen (fehlen in älteren Backups → dann einfach leer).
        recipe.cookingNotes = (backup.cookingNotes ?? []).map {
            CookingNote(date: $0.date, text: $0.text)
        }
    }

    private static func resolveCategory(
        name: String,
        icon: String,
        cache: inout [String: RecipeCategory],
        context: ModelContext
    ) -> RecipeCategory {
        if let existing = cache[name] {
            return existing
        }
        let category = RecipeCategory(name: name, iconName: icon, sortIndex: cache.count, isBuiltIn: false)
        context.insert(category)
        cache[name] = category
        return category
    }

    private static func resolveSubcategory(
        name: String,
        in category: RecipeCategory,
        context: ModelContext
    ) -> RecipeSubcategory {
        if let existing = category.sortedSubcategories.first(where: { $0.name == name }) {
            return existing
        }
        let subcategory = RecipeSubcategory(name: name, sortIndex: category.sortedSubcategories.count)
        category.subcategories = (category.subcategories ?? []) + [subcategory]
        return subcategory
    }

    private static func makeDetails(from backup: SausageBackup) -> SausageSmokingDetails {
        let details = SausageSmokingDetails()
        details.meatWeightKg = backup.meatWeightKg
        details.seasoningPerKg = backup.seasoningPerKg
        details.npsGramsPerKg = backup.npsGramsPerKg
        details.cutterAids = backup.cutterAids
        details.iceWaterPercent = backup.iceWaterPercent
        details.casing = backup.casing
        details.smokingMethodRaw = backup.smokingMethodRaw
        details.smokingTimeMinutes = backup.smokingTimeMinutes
        details.smokingTemperatureCelsius = backup.smokingTemperatureCelsius
        details.scaldingTemperatureCelsius = backup.scaldingTemperatureCelsius
        details.coreTemperatureCelsius = backup.coreTemperatureCelsius
        details.curingDays = backup.curingDays
        details.dryingDays = backup.dryingDays
        details.safetyNotes = backup.safetyNotes
        return details
    }

    // MARK: Helfer

    private static func appVersion() -> String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }
}

/// Fehler beim Wiederherstellen mit freundlicher Meldung.
enum BackupError: LocalizedError {
    case invalidFile

    var errorDescription: String? {
        "Diese Datei ist kein gültiges RezeptWerk-Backup."
    }

    var recoverySuggestion: String? {
        "Tipp: Wähle eine Datei, die mit „Backup erstellen“ in RezeptWerk gespeichert wurde (Endung .json)."
    }
}
