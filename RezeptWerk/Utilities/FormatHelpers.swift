import Foundation

/// Kleine Helfer, um Zahlen und Zeiten überall einheitlich zu formatieren.
enum FormatHelpers {

    // MARK: Zeiten

    /// Formatiert Minuten als lesbaren Text: 45 → „45 Min.“, 80 → „1 Std. 20 Min.“
    static func minutesText(_ minutes: Int) -> String {
        guard minutes > 0 else { return "–" }
        let hours = minutes / 60
        let rest = minutes % 60
        switch (hours, rest) {
        case (0, _): return "\(rest) Min."
        case (_, 0): return "\(hours) Std."
        default: return "\(hours) Std. \(rest) Min."
        }
    }

    /// Timer-Anzeige „mm:ss“, ab einer Stunde „h:mm:ss“.
    static func timerText(seconds: Int) -> String {
        let s = max(0, seconds)
        let hours = s / 3600
        let minutes = (s % 3600) / 60
        let secs = s % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%02d:%02d", minutes, secs)
    }

    // MARK: Mengen

    /// Formatiert eine Zutatenmenge: 2.0 → „2“, 1.5 → „1,5“, 0.33 → „0,33“.
    static func amountText(_ amount: Double?) -> String? {
        guard let amount, amount > 0 else { return nil }
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount))
    }

    /// Wandelt deutsche Zahleneingaben („1,5“) sicher in Double um.
    static func parseAmount(_ text: String) -> Double? {
        let cleaned = text
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: ",", with: ".")
        guard !cleaned.isEmpty else { return nil }
        return Double(cleaned)
    }

    /// Wandelt Texteingaben sicher in ganze Zahlen um (leere Eingabe → nil).
    static func parseInt(_ text: String) -> Int? {
        let cleaned = text.trimmingCharacters(in: .whitespaces)
        guard !cleaned.isEmpty else { return nil }
        return Int(cleaned)
    }

    // MARK: Datum

    /// Relative Angabe wie „vor 3 Tagen“ — für „Zuletzt gekocht“.
    static func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: .now)
    }

    /// Kurzes Datum, z. B. „12.06.2026“.
    static func shortDate(_ date: Date) -> String {
        date.formatted(date: .numeric, time: .omitted)
    }
}
