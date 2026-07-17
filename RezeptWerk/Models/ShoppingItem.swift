import Foundation
import SwiftData

/// Ein Eintrag auf der Einkaufsliste.
///
/// Bewusst **denormalisiert** (kein Verweis aufs Rezept, nur Skalarfelder):
/// Die Liste übersteht das Löschen von Rezepten und bleibt einfach. Da es
/// keine Beziehungen gibt, ist das Modell zudem ohne Weiteres
/// CloudKit-tauglich (alle Felder haben einen Standardwert).
@Model
final class ShoppingItem {

    var name: String = ""

    /// Menge, z. B. 400. `nil` für Einträge ohne Menge („Salz“).
    var amount: Double?

    /// Einheit, z. B. „g“, „ml“, „Stück“. Leer möglich.
    var unit: String = ""

    /// Abgehakt (eingekauft)?
    var isChecked: Bool = false

    /// `true`, wenn der Eintrag von Hand eingetippt wurde (statt aus einem
    /// Rezept/Wochenplan übernommen).
    var isManual: Bool = false

    var createdAt: Date = Date.now

    /// Reihenfolge — für eine stabile Sortierung.
    var sortIndex: Int = 0

    init(
        name: String,
        amount: Double? = nil,
        unit: String = "",
        isManual: Bool = false,
        sortIndex: Int = 0
    ) {
        self.name = name
        self.amount = amount
        self.unit = unit
        self.isManual = isManual
        self.sortIndex = sortIndex
    }

    /// Anzeigetext: „400 g Mehl“, „2 Zwiebeln“, „Salz“.
    var displayText: String {
        var parts: [String] = []
        if let amountText = FormatHelpers.amountText(amount) {
            parts.append(amountText)
        }
        if !unit.isEmpty {
            parts.append(unit)
        }
        parts.append(name)
        return parts.joined(separator: " ")
    }

    /// Schlüssel zum Zusammenfassen gleicher Zutaten (Name + Einheit,
    /// Groß-/Kleinschreibung egal).
    var mergeKey: String {
        name.trimmingCharacters(in: .whitespaces).lowercased()
            + "|"
            + unit.trimmingCharacters(in: .whitespaces).lowercased()
    }
}
