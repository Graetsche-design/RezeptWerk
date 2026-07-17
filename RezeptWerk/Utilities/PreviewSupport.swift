import Foundation
import SwiftData

/// Daten für Xcode-Previews: ein In-Memory-Container mit den
/// Beispielrezepten — ohne die echte Datenbank anzufassen.
///
/// Verwendung in einer Preview:
/// ```swift
/// #Preview {
///     RecipeDetailView(recipe: PreviewSupport.firstRecipe)
///         .modelContainer(PreviewSupport.container)
/// }
/// ```
@MainActor
enum PreviewSupport {

    static let container: ModelContainer = {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        // `Recipe.self` zieht alle verknüpften Modelle automatisch mit ins Schema.
        let container = try! ModelContainer(for: Recipe.self, configurations: configuration)
        SampleDataService.seedIfNeeded(context: container.mainContext)
        return container
    }()

    /// Irgendein Beispielrezept für Detail-/Editor-Previews.
    static var firstRecipe: Recipe {
        let recipes = (try? container.mainContext.fetch(FetchDescriptor<Recipe>())) ?? []
        return recipes.first ?? Recipe(title: "Vorschau-Rezept")
    }

    /// Das Wurst-Beispielrezept (mit Fachdaten-Block).
    static var sausageRecipe: Recipe {
        let recipes = (try? container.mainContext.fetch(FetchDescriptor<Recipe>())) ?? []
        return recipes.first(where: { $0.sausageDetails != nil }) ?? firstRecipe
    }
}
