import SwiftUI
import SwiftData

/// Kleines Blatt zum Ändern der Portionen eines Planeintrags.
///
/// Die Zahl wandert von hier in den Kochmodus und die Einkaufsliste —
/// deshalb wird sie direkt am `PlannedMeal` gespeichert.
struct MealServingsSheet: View {

    let meal: PlannedMeal

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var servings: Int
    @State private var saveFailed = false

    init(meal: PlannedMeal) {
        self.meal = meal
        _servings = State(initialValue: meal.effectiveServings)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper("Portionen: \(servings)", value: $servings, in: 1...50)
                } header: {
                    Text(meal.recipe?.title ?? "Portionen")
                } footer: {
                    if let recipe = meal.recipe {
                        Text("Das Rezept ist für \(recipe.servings) Portionen angelegt. Kochmodus und Einkaufsliste rechnen die Mengen auf die hier gewählte Zahl um.")
                    }
                }
            }
            .navigationTitle("Portionen")
            .navigationBarTitleDisplayMode(.inline)
            .saveErrorAlert($saveFailed)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { save() }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func save() {
        meal.servings = servings
        do {
            try modelContext.save()
        } catch {
            // Nicht gespeichert: Änderung zurücknehmen und Bescheid geben.
            modelContext.rollback()
            saveFailed = true
            return
        }
        dismiss()
    }
}
