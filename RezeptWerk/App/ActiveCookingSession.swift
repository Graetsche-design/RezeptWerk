import Foundation

/// Merkt sich den gerade geöffneten Kochmodus, damit Siri-Kurzbefehle
/// („Nächster Schritt in RezeptWerk“) ihn steuern können — und liefert die
/// gesprochenen Antworten dazu.
///
/// Der Kochmodus meldet sich beim Erscheinen an und beim Verschwinden ab;
/// die Referenz ist schwach, damit hier nichts am Leben gehalten wird.
@MainActor
final class ActiveCookingSession {

    static let shared = ActiveCookingSession()

    private(set) weak var viewModel: CookingModeViewModel?

    /// Ein Kurzbefehl hat gerade geblättert: Siri spricht den Schritt
    /// selbst, das automatische Vorlesen der App soll dieses eine Mal
    /// aussetzen.
    private var suppressAutoRead = false

    static let notOpenMessage = "Der Kochmodus ist gerade nicht geöffnet. Öffne ein Rezept und tippe auf „Kochmodus starten“."

    private init() {}

    func register(_ viewModel: CookingModeViewModel) {
        self.viewModel = viewModel
    }

    /// Meldet den Kochmodus ab — nur, wenn es wirklich dieser ist (ein neu
    /// geöffneter Kochmodus soll nicht vom alten abgemeldet werden).
    func unregister(_ viewModel: CookingModeViewModel) {
        if self.viewModel === viewModel {
            self.viewModel = nil
        }
    }

    /// Liest das Aussetz-Signal fürs automatische Vorlesen und setzt es
    /// zurück.
    func takeSuppressAutoRead() -> Bool {
        defer { suppressAutoRead = false }
        return suppressAutoRead
    }

    // MARK: Kommandos — jedes liefert den Antworttext, den Siri spricht

    func goToNextStep() -> String {
        guard let viewModel else { return Self.notOpenMessage }
        guard !viewModel.isOnFinishPage else {
            return "Du bist schon am Ende. " + CookingSpeech.finishAnnouncement
        }
        suppressAutoRead = true
        viewModel.goToNextStep()
        return CookingSpeech.announcement(for: viewModel)
    }

    func goToPreviousStep() -> String {
        guard let viewModel else { return Self.notOpenMessage }
        guard viewModel.stepIndex > 0 else {
            return "Du bist schon beim ersten Schritt. " + CookingSpeech.announcement(for: viewModel)
        }
        suppressAutoRead = true
        viewModel.goToPreviousStep()
        return CookingSpeech.announcement(for: viewModel)
    }

    func currentStepAnnouncement() -> String {
        guard let viewModel else { return Self.notOpenMessage }
        return CookingSpeech.announcement(for: viewModel)
    }

    /// Startet den Timer des aktuellen Schritts — oder pausiert ihn, wenn
    /// er läuft. Ein abgelaufener Timer wird für den Neustart zurückgesetzt.
    func toggleTimer() -> String {
        guard let viewModel else { return Self.notOpenMessage }
        guard viewModel.hasTimer else {
            return "Schritt \(viewModel.stepIndex + 1) hat keinen Timer."
        }
        if viewModel.timerIsRunning {
            viewModel.pauseTimer()
            return "Timer pausiert bei \(CookingSpeech.spoken(seconds: viewModel.timerRemainingSeconds))."
        }
        if viewModel.timerDidFinish || viewModel.timerRemainingSeconds == 0 {
            viewModel.resetTimer()
        }
        viewModel.toggleTimer()
        return "Timer für Schritt \(viewModel.stepIndex + 1) gestartet: \(CookingSpeech.spoken(seconds: viewModel.timerRemainingSeconds))."
    }
}

/// Baut die gesprochenen Texte des Kochmodus — für die Sprachausgabe in
/// der App und die Antworten an Siri.
enum CookingSpeech {

    static let finishAnnouncement = "Alle Schritte sind geschafft. Guten Appetit!"

    /// „Schritt 3 von 7. Das Steak wenden. Timer: 90 Sekunden.“ — oder der
    /// Abschluss nach dem letzten Schritt.
    @MainActor
    static func announcement(for viewModel: CookingModeViewModel) -> String {
        guard let step = viewModel.currentStep else { return finishAnnouncement }

        let body = step.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let endsWithPunctuation = body.last.map { ".!?…:".contains($0) } ?? true
        var text = "Schritt \(viewModel.stepIndex + 1) von \(viewModel.totalSteps). \(body)"
        if !endsWithPunctuation { text += "." }
        if let seconds = step.timerSeconds, seconds > 0 {
            text += " Timer: \(spoken(seconds: seconds))."
        }
        return text
    }

    /// 90 → „1 Minute 30 Sekunden“, 600 → „10 Minuten“, 3600 → „1 Stunde“.
    static func spoken(seconds: Int) -> String {
        let total = max(0, seconds)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60

        var parts: [String] = []
        if hours > 0 { parts.append(hours == 1 ? "1 Stunde" : "\(hours) Stunden") }
        if minutes > 0 { parts.append(minutes == 1 ? "1 Minute" : "\(minutes) Minuten") }
        if secs > 0 || parts.isEmpty { parts.append(secs == 1 ? "1 Sekunde" : "\(secs) Sekunden") }
        return parts.joined(separator: " ")
    }
}
