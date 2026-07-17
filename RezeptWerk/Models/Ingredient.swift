import Foundation
import SwiftData

/// Eine Zutat eines Rezepts.
///
/// Menge und Einheit sind getrennt gespeichert, damit die App Mengen
/// umrechnen kann (Portionsrechner in der Detailansicht).
@Model
final class Ingredient {

    /// Menge, z. B. 250. `nil` für Zutaten ohne Menge („Salz nach Geschmack“).
    var amount: Double?

    /// Einheit, z. B. „g“, „ml“, „EL“. Leer, wenn stückzahllos („2 Eier“ → „“).
    var unit: String = ""

    /// Name der Zutat, z. B. „Mehl“.
    var name: String = ""

    /// Position in der Zutatenliste (SwiftData-Arrays sind unsortiert).
    var sortIndex: Int = 0

    /// Rückverweis aufs Rezept. Die `inverse`-Deklaration liegt bei `Recipe`.
    var recipe: Recipe?

    init(amount: Double? = nil, unit: String = "", name: String, sortIndex: Int = 0) {
        self.amount = amount
        self.unit = unit
        self.name = name
        self.sortIndex = sortIndex
    }

    /// Anzeigetext mit umgerechneter Menge, z. B. Faktor 1,5: „375 g Mehl“.
    func displayText(scaledBy factor: Double = 1) -> String {
        var parts: [String] = []
        if let amountText = FormatHelpers.amountText(amount.map { $0 * factor }) {
            parts.append(amountText)
        }
        if !unit.isEmpty {
            parts.append(unit)
        }
        parts.append(name)
        return parts.joined(separator: " ")
    }
}
