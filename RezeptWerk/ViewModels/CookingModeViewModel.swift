import Foundation
import Observation
import SwiftData

/// Zustand und Logik des Kochmodus: aktueller Schritt, abgehakte Zutaten
/// und der Schritt-Timer.
///
/// Der Timer ist bewusst **kein** Datenbankobjekt — ein laufender Timer
/// ist flüchtiger Zustand und gehört hierher, nicht in SwiftData.
@MainActor
@Observable
final class CookingModeViewModel {

    let recipe: Recipe

    /// Index des aktuellen Schritts. `steps.count` = Abschluss-Seite.
    var stepIndex = 0

    /// Im Zutaten-Blatt abgehakte Zutaten.
    var checkedIngredients: Set<PersistentIdentifier> = []

    // MARK: Timer-Zustand

    var timerTotalSeconds = 0
    var timerRemainingSeconds = 0
    var timerIsRunning = false
    /// Wird `true`, wenn der Timer abläuft — löst Haptik und die
    /// „Fertig!“-Anzeige aus.
    var timerDidFinish = false

    private var timerTask: Task<Void, Never>?

    /// Zielzeitpunkt des laufenden Timers. Die Restzeit wird immer aus
    /// diesem Datum berechnet — so stimmt sie auch dann noch, wenn die App
    /// zwischendurch im Hintergrund war oder das System kurz gestockt hat.
    private var timerEndDate: Date?

    init(recipe: Recipe) {
        self.recipe = recipe
        prepareTimerForCurrentStep()
    }

    // MARK: Schritte

    var steps: [RecipeStep] { recipe.sortedSteps }
    var totalSteps: Int { steps.count }

    var currentStep: RecipeStep? {
        steps.indices.contains(stepIndex) ? steps[stepIndex] : nil
    }

    /// Nach dem letzten Schritt kommt die Abschluss-Seite.
    var isOnFinishPage: Bool { stepIndex >= totalSteps }

    var progress: Double {
        guard totalSteps > 0 else { return 0 }
        return Double(min(stepIndex + 1, totalSteps)) / Double(totalSteps)
    }

    func goToNextStep() {
        guard stepIndex < totalSteps else { return }
        stepIndex += 1
        prepareTimerForCurrentStep()
    }

    func goToPreviousStep() {
        guard stepIndex > 0 else { return }
        stepIndex -= 1
        prepareTimerForCurrentStep()
    }

    // MARK: Zutaten abhaken

    func toggleIngredient(_ ingredient: Ingredient) {
        let id = ingredient.persistentModelID
        if checkedIngredients.contains(id) {
            checkedIngredients.remove(id)
        } else {
            checkedIngredients.insert(id)
        }
    }

    func isChecked(_ ingredient: Ingredient) -> Bool {
        checkedIngredients.contains(ingredient.persistentModelID)
    }

    // MARK: Timer

    /// Beim Schrittwechsel: Timer stoppen und auf die Vorgabe des neuen
    /// Schritts stellen (falls er einen Timer hat). Nicht automatisch
    /// starten — das entscheidet der Koch.
    func prepareTimerForCurrentStep() {
        pauseTimer()
        timerDidFinish = false
        let seconds = currentStep?.timerSeconds ?? 0
        timerTotalSeconds = max(0, seconds)
        timerRemainingSeconds = timerTotalSeconds
    }

    var hasTimer: Bool { timerTotalSeconds > 0 }

    var timerProgress: Double {
        guard timerTotalSeconds > 0 else { return 0 }
        return Double(timerTotalSeconds - timerRemainingSeconds) / Double(timerTotalSeconds)
    }

    func toggleTimer() {
        if timerIsRunning {
            pauseTimer()
        } else {
            startTimer()
        }
    }

    private func startTimer() {
        guard timerRemainingSeconds > 0 else { return }
        timerIsRunning = true
        timerDidFinish = false

        // Die Restzeit hängt an einem festen ZIELZEITPUNKT statt am Zählen
        // von Schleifendurchläufen. Vorteil: Kommt die App aus dem
        // Hintergrund zurück (oder stockt das System kurz), springt die
        // Anzeige sofort auf die korrekte Restzeit — und ist der Zeitpunkt
        // schon vorbei, klingelt es direkt beim Zurückkommen.
        let endDate = Date.now.addingTimeInterval(Double(timerRemainingSeconds))
        timerEndDate = endDate

        timerTask = Task {
            while !Task.isCancelled && timerIsRunning {
                let remaining = max(0, Int(ceil(endDate.timeIntervalSinceNow)))
                if remaining != timerRemainingSeconds {
                    timerRemainingSeconds = remaining
                }
                if remaining <= 0 {
                    timerIsRunning = false
                    timerDidFinish = true
                    timerEndDate = nil
                    return
                }
                // Kurzes Prüf-Intervall: hält die Anzeige exakt und erkennt
                // die Rückkehr aus dem Hintergrund schnell.
                try? await Task.sleep(for: .milliseconds(200))
            }
        }
    }

    func pauseTimer() {
        // Die Restzeit ein letztes Mal exakt festhalten, dann anhalten.
        if timerIsRunning, let endDate = timerEndDate {
            timerRemainingSeconds = max(0, Int(ceil(endDate.timeIntervalSinceNow)))
        }
        timerIsRunning = false
        timerEndDate = nil
        timerTask?.cancel()
        timerTask = nil
    }

    func resetTimer() {
        pauseTimer()
        timerDidFinish = false
        timerRemainingSeconds = timerTotalSeconds
    }

    // MARK: Abschluss

    /// Merkt sich, dass das Rezept gekocht wurde (für „Zuletzt gekocht“) —
    /// und legt bei nicht-leerem Text eine datierte Koch-Notiz an.
    func finishCooking(in context: ModelContext, noteText: String = "") {
        pauseTimer()
        recipe.lastCookedAt = .now

        let trimmed = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            let note = CookingNote(text: trimmed)
            note.recipe = recipe
            context.insert(note)
        }

        try? context.save()
    }
}
