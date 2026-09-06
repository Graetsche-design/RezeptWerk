import Testing
import Foundation
@testable import RezeptWerk

/// Tests für die Timer-Logik des Kochmodus (Zielzeitpunkt-Rechnung).
@MainActor
struct CookingModeTimerTests {

    private func makeViewModel(timerSeconds: Int = 60) -> CookingModeViewModel {
        let recipe = Recipe(title: "Timer-Test")
        recipe.steps = [RecipeStep(text: "Warten", sortIndex: 0, timerSeconds: timerSeconds)]
        return CookingModeViewModel(recipe: recipe)
    }

    @Test func timerWirdAufSchrittVorgabeGestellt() {
        let vm = makeViewModel(timerSeconds: 90)
        #expect(vm.hasTimer)
        #expect(vm.timerTotalSeconds == 90)
        #expect(vm.timerRemainingSeconds == 90)
        #expect(!vm.timerIsRunning)
    }

    @Test func timerLaeuftMitEchterUhrzeit() async throws {
        let vm = makeViewModel(timerSeconds: 60)
        vm.toggleTimer()
        #expect(vm.timerIsRunning)

        try await Task.sleep(for: .seconds(1.5))
        // Nach 1,5 s Wanduhr: Rest per ceil(58,5) = 59 (± Toleranz).
        #expect((58...60).contains(vm.timerRemainingSeconds))
    }

    @Test func pauseHaeltDieRestzeitFest() async throws {
        let vm = makeViewModel(timerSeconds: 60)
        vm.toggleTimer()
        try await Task.sleep(for: .seconds(1.2))
        vm.pauseTimer()
        let beiPause = vm.timerRemainingSeconds
        #expect(!vm.timerIsRunning)

        try await Task.sleep(for: .seconds(0.8))
        #expect(vm.timerRemainingSeconds == beiPause)
    }

    @Test func fortschrittWirdBerechnet() {
        let vm = makeViewModel(timerSeconds: 100)
        vm.timerRemainingSeconds = 75
        #expect(abs(vm.timerProgress - 0.25) < 0.001)
    }

    // MARK: Mehrere Timer

    private func makeParallelViewModel() -> CookingModeViewModel {
        let recipe = Recipe(title: "Parallel")
        recipe.steps = [
            RecipeStep(text: "Nudeln kochen", sortIndex: 0, timerSeconds: 60),
            RecipeStep(text: "Soße einkochen", sortIndex: 1, timerSeconds: 30),
            RecipeStep(text: "Anrichten", sortIndex: 2),
        ]
        return CookingModeViewModel(recipe: recipe)
    }

    @Test func laufenderTimerUeberlebtDasBlaettern() {
        let vm = makeParallelViewModel()
        vm.toggleTimer()
        vm.goToNextStep()

        // Schritt 1 läuft weiter, Schritt 2 hat einen eigenen, ruhenden Timer.
        #expect(vm.timers[0]?.isRunning == true)
        #expect(vm.hasTimer)
        #expect(!vm.timerIsRunning)
        #expect(vm.otherActiveTimers.map(\.stepIndex) == [0])
    }

    @Test func mehrereTimerLaufenGleichzeitig() {
        let vm = makeParallelViewModel()
        vm.toggleTimer()
        vm.goToNextStep()
        vm.toggleTimer()
        vm.goToNextStep()

        #expect(!vm.hasTimer)
        #expect(vm.hasRunningTimers)
        #expect(vm.otherActiveTimers.map(\.stepIndex) == [0, 1])

        vm.pauseAllTimers()
        #expect(!vm.hasRunningTimers)
        // Pausierte Timer behalten ihre Restzeit statt zu verschwinden.
        #expect((59...60).contains(vm.timers[0]?.remainingSeconds ?? -1))
        #expect(vm.otherActiveTimers.isEmpty)
    }

    @Test func zurueckblaetternZeigtDenLaufendenTimer() {
        let vm = makeParallelViewModel()
        vm.toggleTimer()
        vm.goToNextStep()
        vm.goToPreviousStep()

        #expect(vm.timerIsRunning)
        #expect(vm.otherActiveTimers.isEmpty)
    }

    @Test func abgelaufenerTimerZaehltHoch() async throws {
        let recipe = Recipe(title: "Kurz")
        recipe.steps = [RecipeStep(text: "Warten", sortIndex: 0, timerSeconds: 1)]
        let vm = CookingModeViewModel(recipe: recipe)
        vm.toggleTimer()

        try await Task.sleep(for: .seconds(1.6))
        #expect(vm.timerDidFinish)
        #expect(!vm.timerIsRunning)
        #expect(vm.timerRemainingSeconds == 0)
        #expect(vm.finishedTimerCount == 1)

        vm.resetTimer()
        #expect(!vm.timerDidFinish)
        #expect(vm.timerRemainingSeconds == 1)
    }
}
