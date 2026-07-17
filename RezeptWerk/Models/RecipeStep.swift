import Foundation
import SwiftData

/// Ein einzelner Zubereitungsschritt.
@Model
final class RecipeStep {

    /// Der Anleitungstext des Schritts.
    var text: String = ""

    /// Position in der Schrittliste (SwiftData-Arrays sind unsortiert).
    var sortIndex: Int = 0

    /// Optionaler Timer für diesen Schritt, in Sekunden.
    /// Beispiel: „Steak 90 Sekunden pro Seite grillen“ → 90.
    /// Der Kochmodus bietet dann automatisch einen passenden Timer an.
    var timerSeconds: Int?

    /// Optionales Foto zu diesem Schritt (komprimiertes JPEG).
    /// `.externalStorage` hält die Datenbank schlank (wie bei `RecipeImage`).
    @Attribute(.externalStorage) var imageData: Data?

    /// Rückverweis aufs Rezept. Die `inverse`-Deklaration liegt bei `Recipe`.
    var recipe: Recipe?

    init(text: String, sortIndex: Int = 0, timerSeconds: Int? = nil, imageData: Data? = nil) {
        self.text = text
        self.sortIndex = sortIndex
        self.timerSeconds = timerSeconds
        self.imageData = imageData
    }
}
