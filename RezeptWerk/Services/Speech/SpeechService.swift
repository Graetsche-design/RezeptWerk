import AVFoundation
import Observation

/// Liest Text vor — für den Kochmodus, wenn die Hände nass oder voll sind.
///
/// Nutzt die System-Sprachausgabe (`AVSpeechSynthesizer`, deutsche Stimme).
/// Spricht über die Medien-Lautstärke, damit ein Tipp aufs
/// Lautsprecher-Symbol auch bei umgelegtem Stumm-Schalter hörbar ist —
/// Musik anderer Apps wird währenddessen leiser und danach wieder normal.
@MainActor
@Observable
final class SpeechService: NSObject, AVSpeechSynthesizerDelegate {

    static let shared = SpeechService()

    private let synthesizer = AVSpeechSynthesizer()

    /// `true`, solange gerade gesprochen wird (für das Symbol im Kochmodus).
    private(set) var isSpeaking = false

    private override init() {
        super.init()
        synthesizer.delegate = self
    }

    /// Spricht den Text; eine laufende Ansage wird abgebrochen.
    func speak(_ text: String) {
        stop()
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? session.setActive(true)

        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.voice = AVSpeechSynthesisVoice(language: "de-DE")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.postUtteranceDelay = 0.2
        isSpeaking = true
        synthesizer.speak(utterance)
    }

    func stop() {
        guard synthesizer.isSpeaking else { return }
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }

    /// Wechselt zwischen Vorlesen und Stopp.
    func toggle(_ text: String) {
        if isSpeaking {
            stop()
        } else {
            speak(text)
        }
    }

    // MARK: AVSpeechSynthesizerDelegate

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in self.finished() }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in self.finished() }
    }

    private func finished() {
        isSpeaking = false
        // Audio-Sitzung freigeben, damit andere Apps wieder normal laut werden.
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
