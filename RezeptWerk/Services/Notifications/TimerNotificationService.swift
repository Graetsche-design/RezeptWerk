import Foundation
import UserNotifications

/// Lokale Mitteilung für den Kochmodus-Timer: Klingelt auch dann, wenn
/// die App gerade im Hintergrund ist oder das iPhone gesperrt wurde.
///
/// Bewusst OHNE Delegate: Ist die App im Vordergrund, zeigt iOS keine
/// Banner — dort übernehmen die vorhandene Timer-Anzeige und die Haptik
/// des Kochmodus. Die Mitteilung greift genau in der Lücke dazwischen.
@MainActor
enum TimerNotificationService {

    /// Fester Kennzeichner — es gibt immer höchstens EINE Timer-Mitteilung.
    private static let identifier = "cookingTimer"

    /// Fragt beim allerersten Timer-Start einmalig um Erlaubnis.
    /// Lehnt der Nutzer ab, läuft der Timer wie bisher (nur in der App) —
    /// es wird nicht erneut genervt, das regelt das System.
    static func requestAuthorizationIfNeeded() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound]
        ) { _, _ in }
    }

    /// Plant die Mitteilung für den Zielzeitpunkt des laufenden Timers.
    static func schedule(endDate: Date, recipeTitle: String, stepText: String) {
        let seconds = endDate.timeIntervalSinceNow
        guard seconds > 1 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Timer abgelaufen"
        // Kurzer Schritt-Anriss, damit man am Sperrbildschirm weiß, worum es geht.
        let anriss = stepText.count > 80
            ? String(stepText.prefix(80)) + "…"
            : stepText
        content.body = "\(recipeTitle): \(anriss)"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: seconds,
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    /// Storniert die geplante Timer-Mitteilung (Pause, Reset,
    /// Schrittwechsel, Kochmodus beendet).
    static func cancel() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
