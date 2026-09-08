import SwiftUI

/// Die Import-Vorschau: zeigt alles, was erkannt wurde — übersichtlich
/// und ehrlich (inklusive Original-Text zum Nachschlagen).
///
/// Von hier geht es mit einem Tipp in den vorbefüllten Editor, wo alles
/// korrigiert werden kann. Gespeichert wird erst dort.
struct ImportPreviewView: View {

    let parsed: ParsedRecipe

    @State private var showEditor = false
    @State private var showSavedAlert = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.l) {
                introCard

                if let imageData = parsed.imageData {
                    RecipeImageView(data: imageData)
                        .frame(height: 180)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
                }

                previewCard(title: "Titel", icon: "textformat") {
                    Text(parsed.title.isEmpty ? "– nicht erkannt –" : parsed.title)
                        .font(AppTypography.cardTitle)
                        .foregroundStyle(parsed.title.isEmpty ? AppColors.textSecondary : AppColors.textPrimary)
                }

                if parsed.servings != nil || parsed.prepMinutes != nil || parsed.cookMinutes != nil {
                    previewCard(title: "Eckdaten", icon: "info.circle") {
                        FlowLayout(spacing: AppSpacing.s) {
                            if let servings = parsed.servings {
                                InfoPill(icon: "person.2", text: "\(servings) Portionen")
                            }
                            if let prep = parsed.prepMinutes {
                                InfoPill(icon: "knife", text: "Vorbereitung \(FormatHelpers.minutesText(prep))")
                            }
                            if let cook = parsed.cookMinutes {
                                InfoPill(icon: "flame", text: "Garzeit \(FormatHelpers.minutesText(cook))")
                            }
                        }
                    }
                }

                previewCard(
                    title: "Zutaten",
                    icon: "basket",
                    badge: "\(parsed.ingredients.count)"
                ) {
                    if parsed.ingredients.isEmpty {
                        notRecognizedHint
                    } else {
                        VStack(alignment: .leading, spacing: AppSpacing.s) {
                            ForEach(Array(parsed.ingredients.enumerated()), id: \.offset) { _, ingredient in
                                HStack(alignment: .firstTextBaseline, spacing: AppSpacing.s) {
                                    Text("•")
                                        .foregroundStyle(AppColors.copper)
                                    Text(ingredientText(ingredient))
                                        .font(AppTypography.secondary)
                                        .foregroundStyle(AppColors.textPrimary)
                                }
                            }
                        }
                    }
                }

                previewCard(
                    title: "Zubereitungsschritte",
                    icon: "list.number",
                    badge: "\(parsed.steps.count)"
                ) {
                    if parsed.steps.isEmpty {
                        notRecognizedHint
                    } else {
                        VStack(alignment: .leading, spacing: AppSpacing.m) {
                            ForEach(Array(parsed.steps.enumerated()), id: \.offset) { index, step in
                                HStack(alignment: .firstTextBaseline, spacing: AppSpacing.s) {
                                    Text("\(index + 1).")
                                        .font(AppTypography.secondary.weight(.semibold))
                                        .foregroundStyle(AppColors.copper)
                                    Text(step)
                                        .font(AppTypography.secondary)
                                        .foregroundStyle(AppColors.textPrimary)
                                }
                            }
                        }
                    }
                }

                if !parsed.tags.isEmpty {
                    previewCard(title: "Tags", icon: "tag") {
                        FlowLayout(spacing: AppSpacing.s) {
                            ForEach(parsed.tags, id: \.self) { tag in
                                TagChipView(text: tag)
                            }
                        }
                    }
                }

                if !parsed.rawText.isEmpty {
                    DisclosureGroup {
                        ScrollView {
                            Text(parsed.rawText)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(AppColors.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 280)
                        .padding(.top, AppSpacing.s)
                    } label: {
                        Label("Erkannter Originaltext", systemImage: "doc.plaintext")
                            .font(AppTypography.secondary.weight(.medium))
                            .foregroundStyle(AppColors.textPrimary)
                    }
                    .card()
                }

                Button {
                    showEditor = true
                } label: {
                    Label("Prüfen, anpassen & speichern", systemImage: "checkmark.circle")
                }
                .buttonStyle(.rwPrimary)
            }
            .padding(AppSpacing.screen)
        }
        .screenBackground()
        .navigationTitle("Import-Vorschau")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showEditor) {
            RecipeEditorView(
                recipe: nil,
                prefilledDraft: RecipeDraft(parsed: parsed),
                onSaved: { _ in
                    showSavedAlert = true
                }
            )
        }
        .alert("Rezept gespeichert", isPresented: $showSavedAlert) {
            Button("Prima!") {
                dismiss()
            }
        } message: {
            Text("Du findest es ab jetzt in deiner Rezeptübersicht.")
        }
    }

    // MARK: Bausteine

    private var introCard: some View {
        HStack(alignment: .top, spacing: AppSpacing.m) {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 18))
                .foregroundStyle(AppColors.copper)
            Text("Das hat RezeptWerk erkannt. Im nächsten Schritt kannst du alles prüfen und anpassen — gespeichert wird erst danach.")
                .font(AppTypography.secondary)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    private var notRecognizedHint: some View {
        Text("– nicht automatisch erkannt – du kannst es im Editor ergänzen oder aus dem Originaltext kopieren.")
            .font(AppTypography.caption)
            .foregroundStyle(AppColors.textSecondary)
    }

    private func previewCard<Content: View>(
        title: String,
        icon: String,
        badge: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.m) {
            HStack(spacing: AppSpacing.s) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.copper)
                Text(title)
                    .font(AppTypography.label)
                    .textCase(.uppercase)
                    .kerning(1)
                    .foregroundStyle(AppColors.textSecondary)
                if let badge {
                    Text(badge)
                        .font(AppTypography.caption.weight(.bold))
                        .foregroundStyle(AppColors.backgroundPrimary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(AppColors.copper, in: Capsule())
                }
            }
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    private func ingredientText(_ ingredient: ParsedIngredient) -> String {
        var parts: [String] = []
        if let amount = FormatHelpers.amountText(ingredient.amount) {
            parts.append(amount)
        }
        if !ingredient.unit.isEmpty {
            parts.append(ingredient.unit)
        }
        parts.append(ingredient.name)
        return parts.joined(separator: " ")
    }
}
