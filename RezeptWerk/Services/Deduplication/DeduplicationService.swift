import Foundation
import SwiftData

/// Räumt Duplikate auf, die durch die iCloud-Synchronisierung entstehen.
///
/// Hintergrund: Bei jeder Neuinstallation legt die App die Standard-
/// Kategorien und Beispielrezepte neu an. Schaltet man danach iCloud-Sync
/// ein, kommen die früher bereits synchronisierten Exemplare aus der Cloud
/// dazu — Kategorien und Beispielrezepte erscheinen doppelt oder mehrfach.
/// CloudKit kann solche inhaltsgleichen Datensätze nicht selbst
/// zusammenführen; Apple empfiehlt genau dieses Muster: nach jedem Import
/// deduplizieren.
///
/// Die Zusammenführung ist verlustfrei: Rezepte, Unterkategorien, Tags und
/// Planeinträge werden zuerst auf das verbleibende Exemplar umgehängt, erst
/// dann werden die überzähligen Kopien gelöscht. Die Löschungen werden von
/// CloudKit zurücksynchronisiert — die Cloud räumt sich also gleich mit auf.
@MainActor
enum DeduplicationService {

    /// Führt alle Aufräumschritte aus. Idempotent und schnell, wenn es
    /// nichts zu tun gibt — läuft bei jedem App-Start und nach jedem
    /// erfolgreichen iCloud-Import.
    static func run(context: ModelContext) {
        mergeDuplicateTags(context: context)
        mergeDuplicateCategories(context: context)
        mergeDuplicateSampleRecipes(context: context)
        removeDuplicatePlannedMeals(context: context)
        try? context.save()
    }

    /// Gemeinsamer Vergleichsschlüssel für Namen — gleiche Normalisierung
    /// wie beim Tag-Wiederverwenden im `RecipeImportService`.
    private static func nameKey(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    // MARK: Tags

    /// Gleichnamige Tags zusammenführen (z. B. zweimal „Dutch Oven“):
    /// Rezepte auf das verbleibende Tag umhängen, Kopien löschen.
    private static func mergeDuplicateTags(context: ModelContext) {
        let allTags = (try? context.fetch(FetchDescriptor<RecipeTag>())) ?? []
        let groups = Dictionary(grouping: allTags) { nameKey($0.name) }

        for (_, group) in groups where group.count > 1 {
            // Es bleibt das Tag mit den meisten Rezepten erhalten.
            let survivor = group.sorted { a, b in
                let countA = a.recipes?.count ?? 0
                let countB = b.recipes?.count ?? 0
                if countA != countB { return countA > countB }
                return a.name < b.name
            }.first!
            for loser in group where loser !== survivor {
                for recipe in loser.recipes ?? [] {
                    var tags = recipe.tags ?? []
                    tags.removeAll { $0 === loser }
                    if !tags.contains(where: { $0 === survivor }) {
                        tags.append(survivor)
                    }
                    recipe.tags = tags
                }
                context.delete(loser)
            }
        }
    }

    // MARK: Kategorien

    /// Gleichnamige Kategorien zusammenführen: Rezepte und Unterkategorien
    /// wandern zum verbleibenden Exemplar, die Kopien werden gelöscht.
    private static func mergeDuplicateCategories(context: ModelContext) {
        let allCategories = (try? context.fetch(FetchDescriptor<RecipeCategory>())) ?? []
        let groups = Dictionary(grouping: allCategories) { nameKey($0.name) }
        var survivors: [RecipeCategory] = []

        for (_, group) in groups {
            // Bevorzugt bleibt die mitgelieferte Kategorie mit dem
            // kleinsten Sortier-Index erhalten.
            let survivor = group.sorted { a, b in
                if a.isBuiltIn != b.isBuiltIn { return a.isBuiltIn }
                if a.sortIndex != b.sortIndex { return a.sortIndex < b.sortIndex }
                return (a.subcategories?.count ?? 0) > (b.subcategories?.count ?? 0)
            }.first!
            survivors.append(survivor)

            for loser in group where loser !== survivor {
                merge(loser, into: survivor, context: context)
            }
        }

        // Zum Schluss doppelte Unterkategorien innerhalb jeder
        // verbleibenden Kategorie zusammenführen.
        for category in survivors {
            mergeDuplicateSubcategories(in: category, context: context)
        }
    }

    private static func merge(
        _ loser: RecipeCategory,
        into survivor: RecipeCategory,
        context: ModelContext
    ) {
        // Unterkategorien: Gibt es beim Überlebenden schon eine mit gleichem
        // Namen, wandern nur die Rezepte dorthin. Sonst wird die ganze
        // Unterkategorie umgehängt (eigene Unterkategorien bleiben erhalten).
        for subcategory in loser.subcategories ?? [] {
            let match = (survivor.subcategories ?? []).first {
                nameKey($0.name) == nameKey(subcategory.name)
            }
            if let match {
                for recipe in subcategory.recipes ?? [] {
                    recipe.subcategory = match
                }
            } else {
                subcategory.category = survivor
            }
        }

        for recipe in loser.recipes ?? [] {
            recipe.category = survivor
        }

        // Übrig gebliebene (bereits leergeräumte) Unterkategorien der Kopie
        // verschwinden über die Cascade-Regel mit.
        context.delete(loser)
    }

    /// Doppelte Unterkategorien mit gleichem Namen innerhalb einer Kategorie
    /// zusammenführen.
    private static func mergeDuplicateSubcategories(
        in category: RecipeCategory,
        context: ModelContext
    ) {
        let groups = Dictionary(grouping: category.subcategories ?? []) { nameKey($0.name) }

        for (_, group) in groups where group.count > 1 {
            let survivor = group.sorted { a, b in
                if a.sortIndex != b.sortIndex { return a.sortIndex < b.sortIndex }
                return a.name < b.name
            }.first!
            for loser in group where loser !== survivor {
                for recipe in loser.recipes ?? [] {
                    recipe.subcategory = survivor
                }
                context.delete(loser)
            }
        }
    }

    // MARK: Beispielrezepte

    /// Mehrfach vorhandene Beispielrezepte (gleicher Titel) auf ein Exemplar
    /// reduzieren. Eigene Rezepte werden bewusst NIE angerührt — nur die
    /// mitgelieferten Beispiele (`isSample == true`) können durch das
    /// erneute Anlegen bei Neuinstallationen doppelt entstehen.
    private static func mergeDuplicateSampleRecipes(context: ModelContext) {
        let allRecipes = (try? context.fetch(FetchDescriptor<Recipe>())) ?? []
        let samples = allRecipes.filter(\.isSample)
        let groups = Dictionary(grouping: samples) { nameKey($0.title) }

        for (_, group) in groups where group.count > 1 {
            // Es bleibt das Exemplar erhalten, mit dem der Nutzer schon
            // gearbeitet hat (Favorit, Bewertung, gekocht) — sonst das älteste.
            let survivor = group.sorted { a, b in
                let scoreA = userTraceScore(a)
                let scoreB = userTraceScore(b)
                if scoreA != scoreB { return scoreA > scoreB }
                return a.createdAt < b.createdAt
            }.first!

            for loser in group where loser !== survivor {
                for meal in loser.plannedMeals ?? [] {
                    meal.recipe = survivor
                }
                for tag in loser.tags ?? []
                where !(survivor.tags ?? []).contains(where: { $0 === tag }) {
                    survivor.tags = (survivor.tags ?? []) + [tag]
                }
                // Zutaten, Schritte und Bilder der Kopie sind inhaltsgleich
                // und verschwinden über die Cascade-Regeln mit.
                context.delete(loser)
            }
        }
    }

    /// Je mehr Spuren der Nutzer an einem Exemplar hinterlassen hat,
    /// desto eher bleibt genau dieses erhalten.
    private static func userTraceScore(_ recipe: Recipe) -> Int {
        var score = 0
        if recipe.isFavorite { score += 4 }
        if recipe.rating > 0 { score += 2 }
        if recipe.lastCookedAt != nil { score += 1 }
        return score
    }

    // MARK: Wochenplan

    /// Identische Planeinträge entfernen (gleiches Rezept, gleicher Tag,
    /// gleiche Mahlzeit, gleiche Position). Zwei bewusst angelegte Einträge
    /// desselben Rezepts unterscheiden sich im Sortier-Index und bleiben.
    private static func removeDuplicatePlannedMeals(context: ModelContext) {
        let allMeals = (try? context.fetch(FetchDescriptor<PlannedMeal>())) ?? []
        let groups = Dictionary(grouping: allMeals.filter { $0.recipe != nil }) { meal in
            "\(ObjectIdentifier(meal.recipe!))|\(meal.date.timeIntervalSinceReferenceDate)|\(meal.mealTypeRaw)|\(meal.sortIndex)"
        }

        for (_, group) in groups where group.count > 1 {
            let survivor = group.min { $0.createdAt < $1.createdAt }!
            for loser in group where loser !== survivor {
                context.delete(loser)
            }
        }
    }
}
