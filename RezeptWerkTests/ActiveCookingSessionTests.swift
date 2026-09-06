import Testing
import Foundation
@testable import RezeptWerk

/// Tests für die Siri-Steuerung des Kochmodus und die gesprochenen Texte.
/// Serialisiert, weil alle über die gemeinsame `ActiveCookingSession` gehen.
@MainActor
@Suite(.serialized)
struct ActiveCookingSessionTests {

    private func makeViewModel() -> CookingModeViewModel {
        let recipe = Recipe(title: "Steak")
        recipe.steps = [
            RecipeStep(text: "Steak salzen", sortIndex: 0),
            RecipeStep(text: "Scharf anbraten", sortIndex: 1, timerSeconds: 90),
        ]
        return CookingModeViewModel(recipe: recipe)
    }

    @Test func ohneKochmodusKommtDerHinweis() {
        let session = ActiveCookingSession.shared
        let vm = makeViewModel()
        session.register(vm)
        session.unregister(vm)

        #expect(session.goToNextStep() == ActiveCookingSession.notOpenMessage)
        #expect(session.currentStepAnnouncement() == ActiveCookingSession.notOpenMessage)
        #expect(session.toggleTimer() == ActiveCookingSession.notOpenMessage)
    }

    @Test func naechsterSchrittBlaettertUndSpricht() {
        let session = ActiveCookingSession.shared
        let vm = makeViewModel()
        session.register(vm)
        defer { session.unregister(vm) }

        let antwort = session.goToNextStep()
        #expect(vm.stepIndex == 1)
        #expect(antwort == "Schritt 2 von 2. Scharf anbraten. Timer: 1 Minute 30 Sekunden.")
        // Siri spricht selbst — das automatische Vorlesen setzt genau einmal aus.
        #expect(session.takeSuppressAutoRead())
        #expect(!session.takeSuppressAutoRead())
    }

    @Test func amEndeBleibtEsBeimAbschluss() {
        let session = ActiveCookingSession.shared
        let vm = makeViewModel()
        session.register(vm)
        defer { session.unregister(vm) }

        vm.stepIndex = 2
        let antwort = session.goToNextStep()
        #expect(vm.stepIndex == 2)
        #expect(antwort.contains("Guten Appetit"))
        #expect(!session.takeSuppressAutoRead())
    }

    @Test func zurueckVomErstenSchrittBleibtDort() {
        let session = ActiveCookingSession.shared
        let vm = makeViewModel()
        session.register(vm)
        defer { session.unregister(vm) }

        let antwort = session.goToPreviousStep()
        #expect(vm.stepIndex == 0)
        #expect(antwort.hasPrefix("Du bist schon beim ersten Schritt."))
        #expect(antwort.contains("Schritt 1 von 2. Steak salzen."))
    }

    @Test func timerKommandoStartetUndPausiert() {
        let session = ActiveCookingSession.shared
        let vm = makeViewModel()
        session.register(vm)
        defer {
            vm.pauseAllTimers()
            session.unregister(vm)
        }

        #expect(session.toggleTimer() == "Schritt 1 hat keinen Timer.")

        vm.goToNextStep()
        let start = session.toggleTimer()
        #expect(vm.timerIsRunning)
        #expect(start == "Timer für Schritt 2 gestartet: 1 Minute 30 Sekunden.")

        let pause = session.toggleTimer()
        #expect(!vm.timerIsRunning)
        #expect(pause.hasPrefix("Timer pausiert bei"))
    }

    @Test func sekundenWerdenAlsSprechtextGebaut() {
        #expect(CookingSpeech.spoken(seconds: 90) == "1 Minute 30 Sekunden")
        #expect(CookingSpeech.spoken(seconds: 600) == "10 Minuten")
        #expect(CookingSpeech.spoken(seconds: 3600) == "1 Stunde")
        #expect(CookingSpeech.spoken(seconds: 3661) == "1 Stunde 1 Minute 1 Sekunde")
        #expect(CookingSpeech.spoken(seconds: 0) == "0 Sekunden")
    }
}
