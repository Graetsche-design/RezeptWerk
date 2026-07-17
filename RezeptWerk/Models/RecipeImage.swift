import Foundation
import SwiftData

/// Ein Foto eines Rezepts.
///
/// `.externalStorage` sorgt dafür, dass SwiftData große Bilddaten als
/// eigene Dateien neben der Datenbank ablegt — das hält die Datenbank
/// schnell, ohne dass wir uns selbst um Dateiverwaltung kümmern müssen.
@Model
final class RecipeImage {

    @Attribute(.externalStorage)
    var data: Data = Data()

    /// Position: Bild 0 ist das Titelbild.
    var sortIndex: Int = 0

    /// Rückverweis aufs Rezept. Die `inverse`-Deklaration liegt bei `Recipe`.
    var recipe: Recipe?

    init(data: Data, sortIndex: Int = 0) {
        self.data = data
        self.sortIndex = sortIndex
    }
}
