import CoreSpotlight
import Foundation
import SwiftData
import UniformTypeIdentifiers

/// Macht Rezepte über die iOS-Suche (Spotlight) auffindbar: Wer auf dem
/// Homescreen „Krakauer“ tippt, findet das Rezept — und landet mit einem
/// Tipp direkt in der Detailansicht.
///
/// Indiziert werden Titel, Kategorie, Tags und Zutaten (als Stichwörter),
/// dazu ein kleines Titelbild. Der Index ist nur eine Kopie: Er wird bei
/// jedem Start komplett neu aufgebaut (fängt auch iCloud-Änderungen ab) und
/// bei Speichern, Löschen, Backup-Wiederherstellung und Beispiel-Neuladen
/// nachgezogen. Fehler werden still geschluckt — Spotlight ist ein
/// Suchbeschleuniger, keine Datenquelle.
@MainActor
enum SpotlightIndexService {

    nonisolated static var domainIdentifier: String { "de.rezeptwerk.app.recipes" }

    /// Alles, was Spotlight über ein Rezept wissen muss — ohne
    /// SwiftData-Objekte, damit Bildverkleinerung und Indizierung im
    /// Hintergrund laufen können.
    struct Entry: Sendable {
        let identifier: String
        let title: String
        let description: String
        let keywords: [String]
        let coverImageData: Data?
    }

    // MARK: Index pflegen

    /// Baut den Index für alle Rezepte neu auf.
    static func reindexAll(context: ModelContext) {
        guard CSSearchableIndex.isIndexingAvailable() else { return }
        let recipes = (try? context.fetch(FetchDescriptor<Recipe>())) ?? []
        let entries = recipes.compactMap(entry(for:))

        // Die Spotlight-Objekte entstehen erst in der Hintergrund-Task —
        // dort werden auch die Vorschaubilder verkleinert.
        Task.detached(priority: .utility) {
            let index = CSSearchableIndex.default()
            try? await index.deleteSearchableItems(withDomainIdentifiers: [domainIdentifier])
            try? await index.indexSearchableItems(entries.map(makeItem))
        }
    }

    /// Ein einzelnes Rezept (neu) indizieren — nach dem Speichern.
    static func index(_ recipe: Recipe) {
        guard CSSearchableIndex.isIndexingAvailable(), let entry = entry(for: recipe) else { return }
        Task.detached(priority: .utility) {
            try? await CSSearchableIndex.default().indexSearchableItems([makeItem(entry)])
        }
    }

    /// Ein Rezept aus dem Index nehmen — vor dem Löschen aufrufen, solange
    /// seine Identität noch gültig ist.
    static func remove(_ recipe: Recipe) {
        guard let identifier = identifier(for: recipe) else { return }
        Task.detached(priority: .utility) {
            try? await CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [identifier])
        }
    }

    // MARK: Suchtreffer → Rezept

    /// Löst den Kennzeichner eines angetippten Treffers wieder in das
    /// Rezept auf. `nil`, wenn es inzwischen gelöscht wurde.
    static func recipe(forSpotlightIdentifier identifier: String, context: ModelContext) -> Recipe? {
        guard let data = identifier.data(using: .utf8),
              let modelID = try? JSONDecoder().decode(PersistentIdentifier.self, from: data)
        else { return nil }
        let all = (try? context.fetch(FetchDescriptor<Recipe>())) ?? []
        return all.first { $0.persistentModelID == modelID }
    }

    // MARK: Aufbau

    /// Der Spotlight-Kennzeichner: die kodierte SwiftData-Identität des
    /// Rezepts — stabil, solange die Datenbank dieselbe bleibt.
    static func identifier(for recipe: Recipe) -> String? {
        guard let data = try? JSONEncoder().encode(recipe.persistentModelID) else { return nil }
        return String(decoding: data, as: UTF8.self)
    }

    static func entry(for recipe: Recipe) -> Entry? {
        let title = recipe.title.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty, let identifier = identifier(for: recipe) else { return nil }
        return Entry(
            identifier: identifier,
            title: title,
            description: description(for: recipe),
            keywords: keywords(for: recipe),
            coverImageData: recipe.coverImageData
        )
    }

    /// „Fleisch · Rind · 4 Portionen · 1 Std. 30 Min. — Rindfleisch, Zwiebeln, …“
    static func description(for recipe: Recipe) -> String {
        var parts: [String] = []
        if let category = recipe.category?.name { parts.append(category) }
        if let subcategory = recipe.subcategory?.name { parts.append(subcategory) }
        parts.append("\(recipe.servings) Portionen")
        if recipe.totalMinutes > 0 { parts.append(FormatHelpers.minutesText(recipe.totalMinutes)) }
        var text = parts.joined(separator: " · ")

        let ingredientNames = recipe.sortedIngredients.map(\.name).filter { !$0.isEmpty }
        if !ingredientNames.isEmpty {
            text += " — " + ingredientNames.prefix(6).joined(separator: ", ")
            if ingredientNames.count > 6 { text += ", …" }
        }
        return text
    }

    /// Tags, Zutaten und Kategorie — so findet die Suche das Rezept auch
    /// über „Paprika“ oder „Grill“. Ohne Doppelte (Groß-/Kleinschreibung egal).
    static func keywords(for recipe: Recipe) -> [String] {
        let candidates = recipe.tagNames
            + recipe.sortedIngredients.map(\.name)
            + [recipe.category?.name, recipe.subcategory?.name].compactMap { $0 }

        var seen = Set<String>()
        var result: [String] = []
        for candidate in candidates {
            let cleaned = candidate.trimmingCharacters(in: .whitespaces)
            guard !cleaned.isEmpty, seen.insert(cleaned.lowercased()).inserted else { continue }
            result.append(cleaned)
        }
        return result
    }

    /// Baut das Spotlight-Objekt — läuft im Hintergrund, deshalb ohne
    /// SwiftData-Zugriff (nur der `Entry`).
    nonisolated static func makeItem(_ entry: Entry) -> CSSearchableItem {
        let attributes = CSSearchableItemAttributeSet(contentType: .content)
        attributes.title = entry.title
        attributes.contentDescription = entry.description
        attributes.keywords = entry.keywords
        if let data = entry.coverImageData {
            attributes.thumbnailData = ImageCompressor.thumbnail(data, maxDimension: 240)
        }
        return CSSearchableItem(
            uniqueIdentifier: entry.identifier,
            domainIdentifier: domainIdentifier,
            attributeSet: attributes
        )
    }
}
