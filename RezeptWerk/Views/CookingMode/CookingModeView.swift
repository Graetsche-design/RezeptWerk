import SwiftUI
import SwiftData
import UIKit

/// Der Kochmodus: Vollbild, ruhig, dunkel — gemacht für die Arbeit am Herd.
///
/// - Ein Schritt pro Seite, sehr große Schrift (Größe in den Einstellungen).
/// - Wischen oder große Buttons zum Blättern.
/// - Zutaten jederzeit als Blatt von unten.
/// - Timer, wenn der Schritt einen hat.
/// - Der Bildschirm bleibt an, solange der Kochmodus offen ist.
struct CookingModeView: View {

    @State private var viewModel: CookingModeViewModel
    @State private var showIngredients = false

    /// Optionale Notiz von der Abschlussseite („Wie ist es gelaufen?“).
    @State private var finishNoteText = ""

    /// Zeigt den Hinweis, wenn der Abschluss (Notiz, „zuletzt gekocht“)
    /// nicht gespeichert werden konnte.
    @State private var saveFailed = false

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @AppStorage(SettingsKeys.cookingFontSize)
    private var fontSizeRaw = CookingFontSize.normal.rawValue

    @AppStorage(SettingsKeys.keepScreenOn)
    private var keepScreenOn = false

    init(recipe: Recipe) {
        _viewModel = State(initialValue: CookingModeViewModel(recipe: recipe))
    }

    private var fontScale: Double {
        (CookingFontSize(rawValue: fontSizeRaw) ?? .normal).scale
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            progressBar
            stepPager

            if viewModel.hasTimer && !viewModel.isOnFinishPage {
                StepTimerView(viewModel: viewModel, fontScale: fontScale)
                    .padding(.horizontal, AppSpacing.screen)
                    .padding(.bottom, AppSpacing.m)
            }

            if !viewModel.isOnFinishPage {
                navigationButtons
            }
        }
        .background(AppColors.backgroundPrimary.ignoresSafeArea())
        // Der Kochmodus ist bewusst immer dunkel: ruhig, blendfrei,
        // Werkstatt-Atmosphäre — und alle Theme-Farben ziehen automatisch
        // ihre Dunkel-Variante.
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showIngredients) {
            CookingIngredientsSheet(viewModel: viewModel, fontScale: fontScale)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        // Haptisches Signal, wenn der Timer abläuft.
        .sensoryFeedback(trigger: viewModel.timerDidFinish) { _, didFinish in
            didFinish ? .success : nil
        }
        .saveErrorAlert($saveFailed)
        .onAppear {
            // Bildschirm wachhalten — die zweite bewusste UIKit-Stelle
            // der App (SwiftUI bietet dafür keine eigene API).
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            // Zurück auf die allgemeine Einstellung (nicht stumpf AUS) —
            // sonst würde das Schließen des Kochmodus den Schalter
            // „Bildschirm immer an“ aus den Einstellungen aushebeln.
            UIApplication.shared.isIdleTimerDisabled = keepScreenOn
            viewModel.pauseTimer()
        }
    }

    // MARK: Kopfzeile

    private var header: some View {
        HStack(spacing: AppSpacing.m) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(width: 44, height: 44)
                    .background(AppColors.backgroundElevated, in: Circle())
            }
            .accessibilityLabel("Kochmodus beenden")

            Spacer()

            Text(viewModel.recipe.title)
                .font(AppTypography.cardTitle)
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(1)

            Spacer()

            Button {
                showIngredients = true
            } label: {
                Image(systemName: "list.bullet")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppColors.copper)
                    .frame(width: 44, height: 44)
                    .background(AppColors.backgroundElevated, in: Circle())
            }
            .accessibilityLabel("Zutaten anzeigen")
        }
        .padding(.horizontal, AppSpacing.screen)
        .padding(.vertical, AppSpacing.m)
    }

    private var progressBar: some View {
        VStack(spacing: AppSpacing.xs) {
            ProgressView(value: viewModel.isOnFinishPage ? 1 : viewModel.progress)
                .tint(AppColors.copper)

            Text(viewModel.isOnFinishPage
                 ? "Fertig"
                 : "Schritt \(viewModel.stepIndex + 1) von \(viewModel.totalSteps)")
                .font(AppTypography.cookingMeta(scale: fontScale * 0.85))
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(.horizontal, AppSpacing.screen)
    }

    // MARK: Schritt-Seiten

    private var stepPager: some View {
        TabView(selection: $viewModel.stepIndex) {
            ForEach(Array(viewModel.steps.enumerated()), id: \.offset) { index, step in
                CookingStepPageView(
                    stepNumber: index + 1,
                    step: step,
                    fontScale: fontScale
                )
                .tag(index)
            }

            finishPage
                .tag(viewModel.totalSteps)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.easeInOut(duration: 0.25), value: viewModel.stepIndex)
        // Den Timer stellt das ViewModel selbst um — bei jeder Änderung
        // von `stepIndex`, egal ob per Button oder Wischen (didSet).
    }

    /// Abschluss-Seite nach dem letzten Schritt.
    private var finishPage: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(AppColors.copper)

                Text("Guten Appetit!")
                    .font(AppTypography.screenTitle)
                    .foregroundStyle(AppColors.textPrimary)

                Text("Alle Schritte sind geschafft. Wie ist es geworden?")
                    .font(AppTypography.cookingMeta(scale: fontScale))
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)

                RatingStarsView(rating: viewModel.recipe.rating, size: 30) { newRating in
                    viewModel.recipe.rating = newRating
                    try? modelContext.save()
                }

                // Optionale Koch-Notiz — wird beim „Fertig“-Tippen als
                // datierter Eintrag am Rezept gespeichert.
                TextField(
                    "Notiz: Wie ist es gelaufen? (optional)",
                    text: $finishNoteText,
                    axis: .vertical
                )
                .lineLimit(2...4)
                .font(AppTypography.body)
                .padding(AppSpacing.m)
                .sunken()
                .frame(maxWidth: 320)

                Button {
                    // Nur schließen, wenn das Speichern geklappt hat —
                    // sonst bleibt die Seite (samt Notiz) offen und der
                    // Hinweis erklärt das Problem.
                    if viewModel.finishCooking(in: modelContext, noteText: finishNoteText) {
                        dismiss()
                    } else {
                        saveFailed = true
                    }
                } label: {
                    Label("Fertig", systemImage: "checkmark")
                }
                .buttonStyle(.rwPrimary)
                .frame(maxWidth: 320)
            }
            .padding(AppSpacing.xxl)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: Navigation

    private var navigationButtons: some View {
        HStack(spacing: AppSpacing.m) {
            Button {
                viewModel.goToPreviousStep()
            } label: {
                Label("Zurück", systemImage: "chevron.left")
            }
            .buttonStyle(.rwSecondary)
            .disabled(viewModel.stepIndex == 0)
            .opacity(viewModel.stepIndex == 0 ? 0.4 : 1)

            Button {
                viewModel.goToNextStep()
            } label: {
                if viewModel.stepIndex == viewModel.totalSteps - 1 {
                    Label("Abschließen", systemImage: "checkmark")
                } else {
                    Label("Weiter", systemImage: "chevron.right")
                }
            }
            .buttonStyle(.rwPrimary)
        }
        .padding(.horizontal, AppSpacing.screen)
        .padding(.bottom, AppSpacing.l)
    }
}

#Preview {
    CookingModeView(recipe: PreviewSupport.firstRecipe)
        .modelContainer(PreviewSupport.container)
}
