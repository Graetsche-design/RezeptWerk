import Foundation
import SwiftData

/// Erstellt den SwiftData-Container — wahlweise lokal oder mit
/// iCloud-Synchronisierung (CloudKit).
///
/// Wichtig für die Robustheit: Schlägt der iCloud-Container fehl (z. B.
/// weil die iCloud-Capability in Xcode noch nicht aktiviert ist oder kein
/// iCloud-Account angemeldet ist), fällt die App **automatisch auf den
/// lokalen Speicher zurück** — sie startet also immer, niemals mit Absturz.
@MainActor
enum ModelContainerFactory {

    /// Der CloudKit-Container (muss zur iCloud-Capability in Xcode passen).
    static let cloudContainerID = "iCloud.de.rezeptwerk.app"

    /// Alle SwiftData-Modelle der App.
    private static var schema: Schema {
        Schema([
            Recipe.self,
            Ingredient.self,
            RecipeStep.self,
            RecipeCategory.self,
            RecipeSubcategory.self,
            RecipeTag.self,
            RecipeImage.self,
            SausageSmokingDetails.self,
            PlannedMeal.self,
            ShoppingItem.self,
            CookingNote.self,
        ])
    }

    /// Baut den Container. `iCloudEnabled` kommt aus den Einstellungen.
    static func makeContainer(iCloudEnabled: Bool) -> ModelContainer {
        // 1. Wenn gewünscht: iCloud-Container versuchen.
        if iCloudEnabled {
            let cloudConfig = ModelConfiguration(
                schema: schema,
                cloudKitDatabase: .private(cloudContainerID)
            )
            if let container = try? ModelContainer(for: schema, configurations: cloudConfig) {
                return container
            }
            // Fehlgeschlagen → unten lokal weitermachen (kein Absturz).
        }

        // 2. Lokaler Container (dieselbe Datei wie zuvor — keine Daten gehen verloren).
        let localConfig = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
        if let container = try? ModelContainer(for: schema, configurations: localConfig) {
            return container
        }

        // 3. Allerletzter Notnagel: flüchtiger Speicher, damit die App startet.
        let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        // Wenn selbst das scheitert, ist etwas grundlegend falsch — dann ist
        // ein klarer Absturz besser als stilles Fehlverhalten.
        return try! ModelContainer(for: schema, configurations: memoryConfig)
    }
}
