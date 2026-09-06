import Foundation
import Observation
import SwiftData

/// Ein Timer eines Zubereitungsschritts. Mehrere können gleichzeitig
/// laufen (Nudeln, Soße, Ofen) — jeder hängt an seinem eigenen
/// Zielzeitpunkt und klingelt für sich.
struct StepTimer: Identifiable {
    let stepIndex: Int
    var totalSeconds: Int
    var remainingSeconds: Int
    var isRunning = false
    /// Wird `true`, wenn der Timer abläuft — bis zum Zurücksetzen.
    var didFinish = false
    /// Zielzeitpunkt, solange der Timer läuft.
    var endDate: Date?

    var id: Int { stepIndex }

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(totalSeconds - remainingSeconds) / Double(totalSeconds)
    }

    /// Läuft oder ist gerade abgelaufen — verdient einen Platz in der
    /// Timer-Leiste des Kochmodus.
    var isActive: Bool { isRunning || didFinish }
}

/// Zustand und Logik des Kochmodus: aktueller Schritt, abgehakte Zutaten
/// und die Schritt-Timer.
///
/// Die Timer sind bewusst **keine** Datenbankobjekte — ein laufender Timer
/// ist flüchtiger Zustand und gehört hierher, nicht in SwiftData.
@MainActor
@Observable
final class CookingModeViewModel {

    let recipe: Recipe

    /// Portionen, für die gekocht wird — aus dem Portionsrechner der
    /// Detailansicht oder dem Wochenplan. Standard: die des Rezepts.
    let servings: Int

    /// Index des aktuellen Schritts. `steps.count` = Abschluss-Seite.
    /// Bei jedem Wechsel — egal ob über die Buttons oder durch Wischen im
    /// Pager (Binding) — wird der Timer des neuen Schritts bereitgelegt;
    /// laufende Timer anderer Schritte laufen weiter.
    var stepIndex = 0 {
        didSet {
            guard oldValue != stepIndex else { return }
            prepareTimerForCurrentStep()
        }
    }

    /// Im Zutaten-Blatt abgehakte Zutaten.
    var checkedIngredients: Set<PersistentIdentifier> = []

    // MARK: Timer-Zustand

    /// Alle Timer dieses Kochvorgangs, je Schritt-Index. Ein Eintrag
    /// entsteht, sobald ein Schritt mit Timer aufgerufen wird — und bleibt
    /// samt Restzeit erhalten, wenn der Koch weiterblättert: Laufende Timer
    /// laufen weiter, pausierte behalten ihre Restzeit.
    private(set) var timers: [Int: StepTimer] = [:]

    /// Zählt hoch, wenn irgendein Timer abläuft — Auslöser für die Haptik.
    private(set) var finishedTimerCount = 0

    /// Eine Schleife für alle laufenden Timer.
    private var tickTask: Task<Void, Never>?

    /// - Parameter servings: Portionen, für die gekocht wird. `nil` oder 0
    ///   bedeutet: wie im Rezept.
    init(recipe: Recipe, servings: Int? = nil) {
        self.recipe = recipe
        if let servings, servings > 0 {
            self.servings = servings
        } else {
            self.servings = recipe.servings
        }
        prepareTimerForCurrentStep()
    }

    // MARK: Portionen

    /// Faktor für die Zutatenmengen im Zutaten-Blatt.
    var scaleFactor: Double { recipe.scaleFactor(forServings: servings) }

    /// `true`, wenn für eine andere Portionszahl als im Rezept gekocht wird.
    var isScaled: Bool { servings != recipe.servings }

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
    }

    func goToPreviousStep() {
        guard stepIndex > 0 else { return }
        stepIndex -= 1
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

    // MARK: Timer des aktuellen Schritts

    /// Der Timer des aktuellen Schritts (falls der Schritt einen hat).
    var currentTimer: StepTimer? { timers[stepIndex] }

    var hasTimer: Bool { timerTotalSeconds > 0 }
    var timerTotalSeconds: Int { currentTimer?.totalSeconds ?? 0 }
    var timerRemainingSeconds: Int {
        get { currentTimer?.remainingSeconds ?? 0 }
        set { timers[stepIndex]?.remainingSeconds = max(0, newValue) }
    }
    var timerIsRunning: Bool { currentTimer?.isRunning ?? false }
    var timerDidFinish: Bool { currentTimer?.didFinish ?? false }
    var timerProgress: Double { currentTimer?.progress ?? 0 }

    /// Beim Schrittwechsel: den Timer des neuen Schritts bereitlegen (falls
    /// er einen hat und noch keinen Eintrag). Nicht automatisch starten —
    /// das entscheidet der Koch. Timer anderer Schritte bleiben unberührt;
    /// das ist der Kern des Parallelbetriebs.
    func prepareTimerForCurrentStep() {
        guard timers[stepIndex] == nil,
              let seconds = currentStep?.timerSeconds, seconds > 0 else { return }
        timers[stepIndex] = StepTimer(
            stepIndex: stepIndex,
            totalSeconds: seconds,
            remainingSeconds: seconds
        )
    }

    func toggleTimer() { toggleTimer(forStep: stepIndex) }
    func pauseTimer() { pauseTimer(forStep: stepIndex) }
    func resetTimer() { resetTimer(forStep: stepIndex) }

    // MARK: Alle Timer

    /// Timer anderer Schritte, die laufen oder gerade abgelaufen sind —
    /// für die Leiste im Kochmodus, nach Schritt sortiert.
    var otherActiveTimers: [StepTimer] {
        timers.values
            .filter { $0.isActive && $0.stepIndex != stepIndex }
            .sorted { $0.stepIndex < $1.stepIndex }
    }

    var hasRunningTimers: Bool {
        timers.values.contains { $0.isRunning }
    }

    func toggleTimer(forStep index: Int) {
        guard let timer = timers[index] else { return }
        if timer.isRunning {
            pauseTimer(forStep: index)
        } else {
            startTimer(forStep: index)
        }
    }

    private func startTimer(forStep index: Int) {
        guard var timer = timers[index], timer.remainingSeconds > 0 else { return }

        // Die Restzeit hängt an einem festen ZIELZEITPUNKT statt am Zählen
        // von Schleifendurchläufen. Vorteil: Kommt die App aus dem
        // Hintergrund zurück (oder stockt das System kurz), springt die
        // Anzeige sofort auf die korrekte Restzeit — und ist der Zeitpunkt
        // schon vorbei, klingelt es direkt beim Zurückkommen.
        let endDate = Date.now.addingTimeInterval(Double(timer.remainingSeconds))
        timer.isRunning = true
        timer.didFinish = false
        timer.endDate = endDate
        timers[index] = timer

        // Mitteilung planen: So klingelt der Timer auch, wenn die App in
        // den Hintergrund wandert oder das iPhone gesperrt wird.
        TimerNotificationService.requestAuthorizationIfNeeded()
        TimerNotificationService.schedule(
            stepIndex: index,
            endDate: endDate,
            recipeTitle: recipe.title,
            stepText: steps.indices.contains(index) ? steps[index].text : ""
        )
        ensureTicking()
    }

    func pauseTimer(forStep index: Int) {
        guard var timer = timers[index] else { return }
        // Die Restzeit ein letztes Mal exakt festhalten, dann anhalten.
        if timer.isRunning, let endDate = timer.endDate {
            timer.remainingSeconds = max(0, Int(ceil(endDate.timeIntervalSinceNow)))
        }
        timer.isRunning = false
        timer.endDate = nil
        timers[index] = timer
        // Geplante Timer-Mitteilung zurückziehen.
        TimerNotificationService.cancel(stepIndex: index)
        stopTickingIfIdle()
    }

    func resetTimer(forStep index: Int) {
        pauseTimer(forStep: index)
        guard var timer = timers[index] else { return }
        timer.didFinish = false
        timer.remainingSeconds = timer.totalSeconds
        timers[index] = timer
    }

    /// Alle Timer anhalten — beim Verlassen des Kochmodus.
    func pauseAllTimers() {
        for index in timers.keys {
            pauseTimer(forStep: index)
        }
    }

    private func ensureTicking() {
        guard tickTask == nil else { return }
        tickTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self, self.tick() else { return }
                // Kurzes Prüf-Intervall: hält die Anzeige exakt und erkennt
                // die Rückkehr aus dem Hintergrund schnell.
                try? await Task.sleep(for: .milliseconds(200))
            }
        }
    }

    private func stopTickingIfIdle() {
        guard !hasRunningTimers else { return }
        tickTask?.cancel()
        tickTask = nil
    }

    /// Bringt alle laufenden Timer auf den Stand der Uhr. Gibt `false`
    /// zurück, wenn keiner mehr läuft — die Schleife endet dann.
    private func tick() -> Bool {
        var anyRunning = false
        for (index, var timer) in timers where timer.isRunning {
            guard let endDate = timer.endDate else { continue }
            let remaining = max(0, Int(ceil(endDate.timeIntervalSinceNow)))
            if remaining > 0 {
                anyRunning = true
                if remaining != timer.remainingSeconds {
                    timer.remainingSeconds = remaining
                    timers[index] = timer
                }
            } else {
                timer.remainingSeconds = 0
                timer.isRunning = false
                timer.didFinish = true
                timer.endDate = nil
                timers[index] = timer
                finishedTimerCount += 1
            }
        }
        if !anyRunning {
            tickTask = nil
        }
        return anyRunning
    }

    // MARK: Abschluss

    /// Merkt sich, dass das Rezept gekocht wurde (für „Zuletzt gekocht“) —
    /// und legt bei nicht-leerem Text eine datierte Koch-Notiz an.
    /// Gibt `false` zurück, wenn das Speichern fehlschlägt: Die Änderung
    /// wird zurückgenommen, damit die Notiz nicht still verloren geht —
    /// die View zeigt dann den Hinweis und bleibt offen.
    @discardableResult
    func finishCooking(in context: ModelContext, noteText: String = "") -> Bool {
        pauseAllTimers()
        recipe.lastCookedAt = .now

        let trimmed = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            let note = CookingNote(text: trimmed)
            note.recipe = recipe
            context.insert(note)
        }

        do {
            try context.save()
            return true
        } catch {
            context.rollback()
            return false
        }
    }
}
