import AppIntents

/// Siri-Kurzbefehle für den Kochmodus — freihändig am Herd:
/// „Nächster Schritt in RezeptWerk“, „Schritt vorlesen in RezeptWerk“,
/// „Timer starten in RezeptWerk“ …
///
/// Die Befehle wirken auf den gerade geöffneten Kochmodus
/// (`ActiveCookingSession`) und geben ihre Antwort als Dialog zurück —
/// Siri spricht sie vor. Ist kein Kochmodus offen, sagt Siri das.

struct NextCookingStepIntent: AppIntent {
    static var title: LocalizedStringResource = "Nächster Schritt"
    static var description = IntentDescription("Blättert im geöffneten Kochmodus zum nächsten Schritt und liest ihn vor.")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        .result(dialog: IntentDialog(stringLiteral: ActiveCookingSession.shared.goToNextStep()))
    }
}

struct PreviousCookingStepIntent: AppIntent {
    static var title: LocalizedStringResource = "Vorheriger Schritt"
    static var description = IntentDescription("Blättert im geöffneten Kochmodus einen Schritt zurück und liest ihn vor.")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        .result(dialog: IntentDialog(stringLiteral: ActiveCookingSession.shared.goToPreviousStep()))
    }
}

struct ReadCookingStepIntent: AppIntent {
    static var title: LocalizedStringResource = "Schritt vorlesen"
    static var description = IntentDescription("Liest den aktuellen Schritt des geöffneten Kochmodus vor.")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        .result(dialog: IntentDialog(stringLiteral: ActiveCookingSession.shared.currentStepAnnouncement()))
    }
}

struct ToggleCookingTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Timer starten oder pausieren"
    static var description = IntentDescription("Startet den Timer des aktuellen Schritts im Kochmodus — oder pausiert ihn, wenn er läuft.")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        .result(dialog: IntentDialog(stringLiteral: ActiveCookingSession.shared.toggleTimer()))
    }
}

/// Die Sätze, auf die Siri hört. Jeder muss den App-Namen enthalten.
struct RezeptWerkShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: NextCookingStepIntent(),
            phrases: [
                "Nächster Schritt in \(.applicationName)",
                "Weiter in \(.applicationName)",
                "\(.applicationName) weiter",
            ],
            shortTitle: "Nächster Schritt",
            systemImageName: "chevron.right.circle"
        )
        AppShortcut(
            intent: PreviousCookingStepIntent(),
            phrases: [
                "Vorheriger Schritt in \(.applicationName)",
                "Zurück in \(.applicationName)",
                "\(.applicationName) zurück",
            ],
            shortTitle: "Vorheriger Schritt",
            systemImageName: "chevron.left.circle"
        )
        AppShortcut(
            intent: ReadCookingStepIntent(),
            phrases: [
                "Schritt vorlesen in \(.applicationName)",
                "Vorlesen in \(.applicationName)",
                "\(.applicationName) vorlesen",
            ],
            shortTitle: "Schritt vorlesen",
            systemImageName: "speaker.wave.2"
        )
        AppShortcut(
            intent: ToggleCookingTimerIntent(),
            phrases: [
                "Timer starten in \(.applicationName)",
                "Timer in \(.applicationName)",
                "\(.applicationName) Timer",
            ],
            shortTitle: "Timer starten/pausieren",
            systemImageName: "timer"
        )
    }
}
