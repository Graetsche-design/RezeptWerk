import Foundation
import SwiftData

/// Erzeugt und pflegt die Einkaufsliste.
///
/// Kernidee: Zutaten werden beim Hinzufügen **zusammengefasst** — gleiche
/// Zutat mit gleicher Einheit ergibt einen Eintrag mit summierter Menge
/// (z. B. 2 × „200 g Mehl“ → „400 g Mehl“). Es wird immer in vorhandene,
/// noch **nicht abgehakte** Einträge gemischt.
@MainActor
enum ShoppingListService {

    /// Schlanke Übergabeform einer Zutat.
    struct Entry {
        var amount: Double?
        var unit: String
        var name: String
    }

    // MARK: Hinzufügen

    /// Fügt die Zutaten eines Rezepts hinzu. Gibt die Anzahl verarbeiteter
    /// Zutaten zurück.
    @discardableResult
    static func add(recipe: Recipe, to context: ModelContext) -> Int {
        let entries = recipe.sortedIngredients.map {
            Entry(amount: $0.amount, unit: $0.unit, name: $0.name)
        }
        return add(entries: entries, to: context)
    }

    /// Fügt alle Zutaten der laufenden (Montags-)Woche aus dem Wochenplan
    /// hinzu. Gibt die Anzahl verarbeiteter Zutaten zurück.
    @discardableResult
    static func addCurrentWeek(to context: ModelContext) -> Int {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Montag
        guard let week = calendar.dateInterval(of: .weekOfYear, for: .now) else { return 0 }

        let meals = (try? context.fetch(FetchDescriptor<PlannedMeal>())) ?? []
        let entries = meals
            .filter { week.contains($0.date) }
            .compactMap { $0.recipe }
            .flatMap { recipe in
                recipe.sortedIngredients.map {
                    Entry(amount: $0.amount, unit: $0.unit, name: $0.name)
                }
            }
        return add(entries: entries, to: context)
    }

    /// Fügt einen von Hand eingetippten Eintrag hinzu („2 Zwiebeln“, „Salz“).
    /// Die Zerlegung in Menge/Einheit/Name übernimmt der vorhandene Parser.
    static func addManual(text: String, to context: ModelContext) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let parsed = RecipeTextParser.parseIngredientLine(trimmed)
        let name = parsed.name.isEmpty ? trimmed : parsed.name
        add(
            entries: [Entry(amount: parsed.amount, unit: parsed.unit, name: name)],
            to: context,
            markManual: true
        )
    }

    /// Kern: fügt Zutaten hinzu und fasst gleiche zusammen.
    @discardableResult
    static func add(entries: [Entry], to context: ModelContext, markManual: Bool = false) -> Int {
        let existing = (try? context.fetch(FetchDescriptor<ShoppingItem>())) ?? []
        // Nur offene Einträge sind Ziel des Zusammenfassens.
        var openByKey = Dictionary(
            existing.filter { !$0.isChecked }.map { ($0.mergeKey, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        var nextSortIndex = (existing.map(\.sortIndex).max() ?? -1) + 1
        var processed = 0

        for entry in entries {
            let cleanName = entry.name.trimmingCharacters(in: .whitespaces)
            guard !cleanName.isEmpty else { continue }
            processed += 1

            let key = mergeKey(name: cleanName, unit: entry.unit)
            if let item = openByKey[key] {
                // Vorhandenen offenen Eintrag ergänzen.
                if let add = entry.amount {
                    item.amount = (item.amount ?? 0) + add
                }
            } else {
                let item = ShoppingItem(
                    name: cleanName,
                    amount: entry.amount,
                    unit: entry.unit.trimmingCharacters(in: .whitespaces),
                    isManual: markManual,
                    sortIndex: nextSortIndex
                )
                context.insert(item)
                openByKey[key] = item
                nextSortIndex += 1
            }
        }

        try? context.save()
        return processed
    }

    // MARK: Aufräumen

    static func clearChecked(in context: ModelContext) {
        let items = (try? context.fetch(FetchDescriptor<ShoppingItem>())) ?? []
        for item in items where item.isChecked {
            context.delete(item)
        }
        try? context.save()
    }

    static func clearAll(in context: ModelContext) {
        let items = (try? context.fetch(FetchDescriptor<ShoppingItem>())) ?? []
        for item in items {
            context.delete(item)
        }
        try? context.save()
    }

    // MARK: Helfer

    private static func mergeKey(name: String, unit: String) -> String {
        name.trimmingCharacters(in: .whitespaces).lowercased()
            + "|"
            + unit.trimmingCharacters(in: .whitespaces).lowercased()
    }
}
