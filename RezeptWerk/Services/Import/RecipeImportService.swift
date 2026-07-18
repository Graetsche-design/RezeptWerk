import Foundation
import SwiftData

/// Zentrale Stelle zum Speichern und Löschen von Rezepten.
///
/// Egal ob neues Rezept, Bearbeitung oder Import — gespeichert wird
/// **immer** über `save(draft:updating:in:)`. So gibt es genau eine
/// Stelle, an der ein `RecipeDraft` in SwiftData-Objekte übersetzt wird.
@MainActor
enum RecipeImportService {

    /// Erstellt aus einem Draft ein neues Rezept (`updating: nil`) oder
    /// aktualisiert ein bestehendes.
    @discardableResult
    static func save(draft: RecipeDraft, updating existing: Recipe?, in context: ModelContext) throws -> Recipe {
        let recipe: Recipe
        if let existing {
            recipe = existing
        } else {
            recipe = Recipe(title: "")
            context.insert(recipe)
        }

        // Grunddaten.
        recipe.title = draft.title.trimmingCharacters(in: .whitespaces)
        recipe.servings = max(1, draft.servings)
        recipe.prepMinutes = FormatHelpers.parseInt(draft.prepMinutesText)
        recipe.cookMinutes = FormatHelpers.parseInt(draft.cookMinutesText)
        recipe.restMinutes = FormatHelpers.parseInt(draft.restMinutesText)
        recipe.difficulty = draft.difficulty
        recipe.rating = draft.rating
        recipe.isFavorite = draft.isFavorite
        recipe.suitableMealTypes = MealType.allCases.filter { draft.suitableMealTypes.contains($0) }
        recipe.notes = draft.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        recipe.sourceText = draft.sourceText.trimmingCharacters(in: .whitespaces)
        recipe.sourceURLString = draft.sourceURLText.trimmingCharacters(in: .whitespaces)

        // Kategorie — die Unterkategorie muss zur Kategorie passen.
        // Aus einer empfangenen Datei vorgemerkte, hier noch unbekannte
        // Kategorien/Unterkategorien (`RecipeDraft.pendingCategoryName`)
        // werden erst jetzt — beim Speichern — wirklich angelegt.
        let category = draft.category ?? makePendingCategory(for: draft, in: context)
        recipe.category = category
        if let subcategory = draft.subcategory, subcategory.category === category {
            recipe.subcategory = subcategory
        } else if let category, let subName = draft.pendingSubcategoryName {
            recipe.subcategory = resolveSubcategory(named: subName, in: category)
        } else {
            recipe.subcategory = nil
        }

        // Zutaten, Schritte und Bilder werden komplett ersetzt —
        // die einfachste fehlersichere Strategie (kein Abgleich nötig).
        for old in recipe.sortedIngredients { context.delete(old) }
        recipe.ingredients = draft.ingredients
            .filter { !$0.isEmpty }
            .enumerated()
            .map { index, draftIngredient in
                Ingredient(
                    amount: FormatHelpers.parseAmount(draftIngredient.amountText),
                    unit: draftIngredient.unit.trimmingCharacters(in: .whitespaces),
                    name: draftIngredient.name.trimmingCharacters(in: .whitespaces),
                    sortIndex: index
                )
            }

        for old in recipe.sortedSteps { context.delete(old) }
        recipe.steps = draft.steps
            .filter { !$0.isEmpty }
            .enumerated()
            .map { index, draftStep in
                RecipeStep(
                    text: draftStep.text.trimmingCharacters(in: .whitespacesAndNewlines),
                    sortIndex: index,
                    timerSeconds: timerSeconds(fromMinutesText: draftStep.timerMinutesText),
                    imageData: draftStep.imageData
                )
            }

        for old in recipe.sortedImages { context.delete(old) }
        recipe.images = draft.imageDatas
            .enumerated()
            .map { index, data in RecipeImage(data: data, sortIndex: index) }

        // Tags wiederverwenden oder neu anlegen.
        recipe.tags = resolveTags(names: draft.tagNames, in: context)

        // Fachdaten Wurst & Räuchern.
        if draft.includeSausageDetails {
            let details = recipe.sausageDetails ?? SausageSmokingDetails()
            details.meatWeightKg = FormatHelpers.parseAmount(draft.meatWeightText)
            details.seasoningPerKg = draft.seasoningPerKg.trimmingCharacters(in: .whitespacesAndNewlines)
            details.npsGramsPerKg = FormatHelpers.parseAmount(draft.npsText)
            details.cutterAids = draft.cutterAids.trimmingCharacters(in: .whitespaces)
            details.iceWaterPercent = FormatHelpers.parseAmount(draft.iceWaterText)
            details.casing = draft.casing.trimmingCharacters(in: .whitespaces)
            details.smokingMethod = draft.smokingMethod
            details.smokingTimeMinutes = FormatHelpers.parseInt(draft.smokingTimeText)
            details.smokingTemperatureCelsius = FormatHelpers.parseInt(draft.smokingTempText)
            details.scaldingTemperatureCelsius = FormatHelpers.parseInt(draft.scaldingTempText)
            details.coreTemperatureCelsius = FormatHelpers.parseInt(draft.coreTempText)
            details.curingDays = FormatHelpers.parseInt(draft.curingDaysText)
            details.dryingDays = FormatHelpers.parseInt(draft.dryingDaysText)
            details.safetyNotes = draft.safetyNotes.trimmingCharacters(in: .whitespacesAndNewlines)
            recipe.sausageDetails = details
        } else if let details = recipe.sausageDetails {
            context.delete(details)
            recipe.sausageDetails = nil
        }

        recipe.updatedAt = .now
        try context.save()
        return recipe
    }

    /// Löscht ein Rezept samt Zutaten, Schritten, Bildern und Fachdaten
    /// (cascade) — die Tags bleiben für andere Rezepte erhalten.
    /// Gibt `false` zurück, wenn das Speichern fehlschlägt; die Löschung
    /// wird dann zurückgenommen, damit nichts still verloren geht.
    @discardableResult
    static func delete(_ recipe: Recipe, in context: ModelContext) -> Bool {
        context.delete(recipe)
        do {
            try context.save()
            return true
        } catch {
            context.rollback()
            return false
        }
    }

    // MARK: Helfer

    /// Legt die im Draft vorgemerkte Kategorie an (Rezept-Tausch) — oder
    /// verwendet eine inzwischen vorhandene gleichen Namens, z. B. wenn sie
    /// zwischenzeitlich per iCloud dazugekommen ist.
    private static func makePendingCategory(
        for draft: RecipeDraft,
        in context: ModelContext
    ) -> RecipeCategory? {
        guard let name = draft.pendingCategoryName else { return nil }

        let existing = (try? context.fetch(FetchDescriptor<RecipeCategory>())) ?? []
        if let match = existing.first(where: { $0.name.lowercased() == name.lowercased() }) {
            return match
        }

        let category = RecipeCategory(
            name: name,
            iconName: draft.pendingCategoryIcon ?? "fork.knife",
            sortIndex: existing.count,
            isBuiltIn: false
        )
        context.insert(category)
        return category
    }

    /// Verwendet eine vorhandene Unterkategorie gleichen Namens oder legt
    /// sie neu an (gleiches Muster wie bei der Backup-Wiederherstellung).
    private static func resolveSubcategory(
        named name: String,
        in category: RecipeCategory
    ) -> RecipeSubcategory {
        if let existing = category.sortedSubcategories.first(where: {
            $0.name.lowercased() == name.lowercased()
        }) {
            return existing
        }
        let subcategory = RecipeSubcategory(name: name, sortIndex: category.sortedSubcategories.count)
        category.subcategories = (category.subcategories ?? []) + [subcategory]
        return subcategory
    }

    /// „1,5“ Minuten → 90 Sekunden.
    private static func timerSeconds(fromMinutesText text: String) -> Int? {
        guard let minutes = FormatHelpers.parseAmount(text), minutes > 0 else { return nil }
        return Int((minutes * 60).rounded())
    }

    /// Sucht vorhandene Tags (Groß-/Kleinschreibung egal) und legt fehlende
    /// neu an — so entstehen keine Duplikate wie „Grill“ und „grill“.
    static func resolveTags(names: [String], in context: ModelContext) -> [RecipeTag] {
        let cleanedNames = names
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        guard !cleanedNames.isEmpty else { return [] }

        let existingTags = (try? context.fetch(FetchDescriptor<RecipeTag>())) ?? []
        var tagsByLowercasedName = Dictionary(
            existingTags.map { ($0.name.lowercased(), $0) },
            uniquingKeysWith: { first, _ in first }
        )

        var result: [RecipeTag] = []
        var alreadyAdded = Set<String>()

        for name in cleanedNames {
            let key = name.lowercased()
            guard !alreadyAdded.contains(key) else { continue }
            alreadyAdded.insert(key)

            if let existing = tagsByLowercasedName[key] {
                result.append(existing)
            } else {
                let newTag = RecipeTag(name: name)
                context.insert(newTag)
                tagsByLowercasedName[key] = newTag
                result.append(newTag)
            }
        }
        return result
    }
}
