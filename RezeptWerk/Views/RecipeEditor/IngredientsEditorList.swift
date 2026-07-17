import SwiftUI

/// Bearbeitbare Zutatenliste im Editor: Menge | Einheit | Name,
/// mit Wischen-zum-Löschen, Umsortieren (über „Bearbeiten“) und
/// „Zutat hinzufügen“.
struct IngredientsEditorList: View {

    @Bindable var draft: RecipeDraft

    var body: some View {
        ForEach($draft.ingredients) { $ingredient in
            HStack(spacing: AppSpacing.s) {
                TextField("Menge", text: $ingredient.amountText)
                    .keyboardType(.decimalPad)
                    .frame(width: 56)
                    .multilineTextAlignment(.trailing)

                TextField("Einheit", text: $ingredient.unit)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .frame(width: 64)

                TextField("Zutat", text: $ingredient.name)
            }
        }
        .onDelete { offsets in
            draft.ingredients.remove(atOffsets: offsets)
            if draft.ingredients.isEmpty {
                draft.addIngredient()
            }
        }
        .onMove { source, destination in
            draft.ingredients.move(fromOffsets: source, toOffset: destination)
        }

        Button {
            draft.addIngredient()
        } label: {
            Label("Zutat hinzufügen", systemImage: "plus.circle.fill")
                .foregroundStyle(AppColors.copper)
        }
    }
}
