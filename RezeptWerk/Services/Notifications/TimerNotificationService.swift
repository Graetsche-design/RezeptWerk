import Foundation
import UserNotifications

/// Lokale Mitteilungen für die Kochmodus-Timer: Klingeln auch dann, wenn
/// die App gerade im Hintergrund ist oder das iPhone gesperrt wurde.
///
/// Bewusst OHNE Delegate: Ist die App im Vordergrund, zeigt iOS keine
/// Banner — dort übernehmen die vorhandene Timer-Anzeige und die Haptik
/// des Kochmodus. Die Mitteilung greift genau in der Lücke dazwischen.
@MainActor
enum TimerNotificationService {

    /// Kennzeichner je Schritt — mehrere Timer bedeuten mehrere
    /// Mitteilungen, eine pro laufendem Schritt-Timer.
    private static func identifier(forStep stepIndex: Int) -> String {
        "cookingTimer.step\(stepIndex)"
    }

    /// Fragt beim allerersten Timer-Start einmalig um Erlaubnis.
    /// Lehnt der Nutzer ab, läuft der Timer wie bisher (nur in der App) —
    /// es wird nicht erneut genervt, das regelt das System.
    static func requestAuthorizationIfNeeded() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound]
        ) { _, _ in }
    }

    /// Plant die Mitteilung für den Zielzeitpunkt eines laufenden Timers.
    static func schedule(stepIndex: Int, endDate: Date, recipeTitle: String, stepText: String) {
        let seconds = endDate.timeIntervalSinceNow
        guard seconds > 1 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Timer abgelaufen · Schritt \(stepIndex + 1)"
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
            identifier: identifier(forStep: stepIndex),
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    /// Storniert die geplante Mitteilung eines Timers (Pause, Reset,
    /// Kochmodus beendet).
    static func cancel(stepIndex: Int) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [identifier(forStep: stepIndex)])
    }
}
