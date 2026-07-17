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
}
