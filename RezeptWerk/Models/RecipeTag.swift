import Foundation
import SwiftData

/// Ein frei vergebbares Schlagwort, z. B. „schnell“, „Dutch Oven“, „Sonntag“.
///
/// Tags sind eine n:m-Beziehung: Ein Tag kann an beliebig vielen Rezepten
/// hängen. Beim Speichern sorgt der `RecipeImportService` dafür, dass
/// gleichnamige Tags wiederverwendet statt doppelt angelegt werden.
@Model
final class RecipeTag {

    var name: String = ""

    /// Rezepte mit diesem Tag.
    /// Die `inverse`-Deklaration liegt bei `Recipe.tags`.
    /// Optional wegen CloudKit (jede Beziehung muss optional sein).
    var recipes: [Recipe]?

    init(name: String) {
        self.name = name
    }
}
