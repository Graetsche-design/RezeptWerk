import SwiftUI
import SwiftData
import UIKit

/// Der Kochmodus: Vollbild, ruhig, dunkel — gemacht für die Arbeit am Herd.
///
/// - Ein Schritt pro Seite, sehr große Schrift (Größe in den Einstellungen).
/// - Wischen oder große Buttons zum Blättern — oder freihändig per Siri
///   („Nächster Schritt in RezeptWerk“, siehe `CookingIntents`).
/// - Vorlesen des Schritts über das Lautsprecher-Symbol, auf Wunsch
///   automatisch bei jedem Schrittwechsel.
/// - Zutaten jederzeit als Blatt von unten.
/// - Timer, wenn der Schritt einen hat — mehrere laufen parallel weiter,
///   auch beim Blättern; die Leiste oben zeigt die Timer anderer Schritte.
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

    /// Jeden neuen Schritt automatisch vorlesen (Einstellungen → Kochmodus).
    @AppStorage(SettingsKeys.cookingAutoRead)
    private var autoRead = false

    /// - Parameter servings: Portionen, für die gekocht wird (Portionsrechner
    ///   oder Wochenplan). `nil` oder 0 = wie im Rezept.
    init(recipe: Recipe, servings: Int? = nil) {
        _viewModel = State(initialValue: CookingModeViewModel(recipe: recipe, servings: servings))
    }

    private var fontScale: Double {
        (CookingFontSize(rawValue: fontSizeRaw) ?? .normal).scale
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            progressBar

            if !viewModel.otherActiveTimers.isEmpty {
                activeTimersStrip
            }

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
        // Haptisches Signal, wenn irgendein Timer abläuft.
        .sensoryFeedback(trigger: viewModel.finishedTimerCount) { old, new in
            new > old ? .success : nil
        }
        .saveErrorAlert($saveFailed)
        .onAppear {
            // Bildschirm wachhalten — die zweite bewusste UIKit-Stelle
            // der App (SwiftUI bietet dafür keine eigene API).
            UIApplication.shared.isIdleTimerDisabled = true
            // Für Siri-Kurzbefehle („Nächster Schritt in RezeptWerk“).
            ActiveCookingSession.shared.register(viewModel)
            if autoRead {
                readCurrentStep()
            }
        }
        .onDisappear {
            // Zurück auf die allgemeine Einstellung (nicht stumpf AUS) —
            // sonst würde das Schließen des Kochmodus den Schalter
            // „Bildschirm immer an“ aus den Einstellungen aushebeln.
            UIApplication.shared.isIdleTimerDisabled = keepScreenOn
            viewModel.pauseAllTimers()
            SpeechService.shared.stop()
            ActiveCookingSession.shared.unregister(viewModel)
        }
        .onChange(of: viewModel.stepIndex) { _, _ in
            // Hat Siri geblättert, spricht Siri den Schritt selbst.
            if ActiveCookingSession.shared.takeSuppressAutoRead() { return }
            if autoRead {
                readCurrentStep()
            } else {
                // Eine laufende Ansage gehört zum alten Schritt.
                SpeechService.shared.stop()
            }
        }
    }

    /// Liest den aktuellen Schritt (oder den Abschluss) vor.
    private func readCurrentStep() {
        SpeechService.shared.speak(CookingSpeech.announcement(for: viewModel))
    }

    // MARK: Timer-Leiste

    /// Timer anderer Schritte, die laufen oder gerade abgelaufen sind —
    /// antippen springt zum Schritt.
    private var activeTimersStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.s) {
                ForEach(viewModel.otherActiveTimers) { timer in
                    Button {
                        viewModel.stepIndex = timer.stepIndex
                    } label: {
                        HStack(spacing: AppSpacing.xs) {
                            Image(systemName: timer.didFinish ? "bell.fill" : "timer")
                            Text(timer.didFinish
                                 ? "Schritt \(timer.stepIndex + 1): fertig!"
                                 : "Schritt \(timer.stepIndex + 1) · \(FormatHelpers.timerText(seconds: timer.remainingSeconds))")
                                .monospacedDigit()
                        }
                        .font(AppTypography.cookingMeta(scale: fontScale * 0.85).weight(.semibold))
                        .foregroundStyle(timer.didFinish ? .white : AppColors.copper)
                        .padding(.horizontal, AppSpacing.m)
                        .padding(.vertical, AppSpacing.s)
                        .background(
                            timer.didFinish
                                ? AnyShapeStyle(AppColors.copper)
                                : AnyShapeStyle(AppColors.backgroundElevated),
                            in: Capsule()
                        )
                        .overlay(
                            Capsule().strokeBorder(
                                timer.didFinish ? Color.clear : AppColors.copper.opacity(0.6),
                                lineWidth: 1
                            )
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(timer.didFinish
                                        ? "Timer von Schritt \(timer.stepIndex + 1) abgelaufen"
                                        : "Timer von Schritt \(timer.stepIndex + 1) läuft, zum Schritt springen")
                }
            }
            .padding(.horizontal, AppSpacing.screen)
        }
        .padding(.top, AppSpacing.s)
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

            // Vorlesen — nochmal tippen stoppt.
            Button {
                SpeechService.shared.toggle(CookingSpeech.announcement(for: viewModel))
            } label: {
                let speaking = SpeechService.shared.isSpeaking
                Image(systemName: speaking ? "speaker.wave.2.fill" : "speaker.wave.2")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(speaking ? .white : AppColors.copper)
                    .frame(width: 44, height: 44)
                    .background(
                        speaking ? AnyShapeStyle(AppColors.copper) : AnyShapeStyle(AppColors.backgroundElevated),
                        in: Circle()
                    )
            }
            .accessibilityLabel(SpeechService.shared.isSpeaking ? "Vorlesen stoppen" : "Schritt vorlesen")

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
