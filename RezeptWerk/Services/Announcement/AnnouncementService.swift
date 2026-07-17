import Foundation

/// Eine Meldung des Entwicklers an alle Nutzer — z. B. „Demnächst erscheint
/// ein Update, bitte vorher ein Backup erstellen“.
///
/// Die Meldung liegt als kleine JSON-Datei auf dem eigenen Webspace (Vorlage:
/// Projektordner `Server/`, Arbeitsablauf: ANLEITUNG.md). Die App lädt die
/// Datei beim Start und zeigt den Text als Hinweisfenster an. So lassen sich
/// Hinweise verteilen, ohne ein App-Update zu veröffentlichen — und ganz
/// ohne Push-Dienste oder Drittanbieter.
struct Announcement: Decodable, Equatable {
    /// Überschrift des Hinweisfensters (optional, darf leer sein).
    var titel: String?
    /// Der eigentliche Hinweistext. Leer = keine Meldung, kein Fenster.
    var nachricht: String
    /// Optionaler Stichtag, z. B. „01.08.2026“ (auch „2026-08-01“ geht).
    /// Bis **einschließlich** diesem Tag erscheint die Meldung einmal pro
    /// Tag erneut — auch wenn sie schon bestätigt wurde. Nach dem Tag
    /// verschwindet sie von selbst. Leer oder weggelassen = die Meldung
    /// erscheint nur ein einziges Mal (bis der Text geändert wird).
    var bis: String?

    /// Kennzeichen, über das sich die App merkt, welche Meldung der Nutzer
    /// bereits bestätigt hat. Es ist einfach der Text selbst — ändert sich
    /// die Meldung auf dem Server, erscheint das Hinweisfenster automatisch
    /// wieder. So muss beim Veröffentlichen keine Nummer o. Ä. gepflegt
    /// werden.
    var identity: String { "\(titel ?? "")|\(nachricht)" }
}

/// Lädt die Ankündigungs-Datei vom Server und entscheidet, ob sie dem
/// Nutzer angezeigt werden muss.
enum AnnouncementService {

    /// Die Adresse der Ankündigungs-Datei auf dem eigenen Server.
    ///
    /// Die Datei liegt auf dem Webspace von kochenmitreima.de (Ordner
    /// `Server/`). Meldung veröffentlichen = dort Titel und Text in die
    /// JSON-Datei schreiben; Meldung beenden = `nachricht` leeren. Der
    /// Ablauf steht Schritt für Schritt in der ANLEITUNG.md. Zieht die
    /// Datei einmal um, einfach hier die neue Adresse eintragen — sie muss
    /// mit `https://` beginnen.
    static let announcementURL = "https://kochenmitreima.de/Server/rezeptwerk-ankuendigung.json"

    /// UserDefaults-Schlüssel: welche Meldung wurde bereits bestätigt?
    private static let dismissedKey = "announcement.dismissedIdentity"

    /// UserDefaults-Schlüssel: an welchem Tag wurde zuletzt bestätigt?
    /// (Nur für Meldungen mit Stichtag relevant — „einmal pro Tag“.)
    private static let dismissedDayKey = "announcement.dismissedDay"

    /// Lädt die aktuelle Meldung. Gibt `nil` zurück, wenn es keine gibt, der
    /// Nutzer sie schon bestätigt hat oder etwas schiefgeht (kein Internet,
    /// Datei fehlt, Tippfehler im JSON …) — ein Fehler stört den App-Start
    /// also nie, das Hinweisfenster bleibt dann einfach weg.
    static func fetchPending() async -> Announcement? {
        // Platzhalter noch nicht ersetzt → Funktion ist inaktiv.
        guard !announcementURL.contains("DEINE-DOMAIN"),
              let url = URL(string: announcementURL) else { return nil }

        // Immer frisch vom Server laden (nicht aus einem Zwischenspeicher),
        // damit eine neue Meldung sofort beim nächsten App-Start ankommt.
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 10

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200,
              let announcement = try? JSONDecoder().decode(Announcement.self, from: data)
        else { return nil }

        // Leere Nachricht bedeutet bewusst „zurzeit keine Meldung“ —
        // die Datei kann dauerhaft auf dem Server liegen bleiben.
        let text = announcement.nachricht.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }

        // Stichtag auswerten (falls angegeben): Liegt er in der
        // Vergangenheit, ist die Meldung automatisch vorbei.
        let today = Calendar.current.startOfDay(for: .now)
        let deadline = announcement.bis.flatMap(parseDeadline)
        if let deadline, today > deadline { return nil }

        // Wurde genau diese Meldung schon bestätigt?
        if UserDefaults.standard.string(forKey: dismissedKey) == announcement.identity {
            // Ohne Stichtag gilt: einmal bestätigt = nie wieder zeigen.
            guard deadline != nil else { return nil }

            // Mit Stichtag erscheint sie jeden Tag aufs Neue — aber
            // höchstens einmal pro Tag: Wurde heute schon bestätigt,
            // kommt sie erst morgen wieder.
            if UserDefaults.standard.string(forKey: dismissedDayKey) == dayString(.now) {
                return nil
            }
        }

        return announcement
    }

    /// Merkt sich, dass der Nutzer diese Meldung (heute) bestätigt hat.
    static func markDismissed(_ announcement: Announcement) {
        UserDefaults.standard.set(announcement.identity, forKey: dismissedKey)
        UserDefaults.standard.set(dayString(.now), forKey: dismissedDayKey)
    }

    // MARK: Datums-Helfer

    /// Wandelt den Stichtag-Text („01.08.2026“ oder „2026-08-01“) in ein
    /// Datum um (Tagesbeginn). Unlesbare Angaben zählen als „kein Stichtag“,
    /// damit ein Tippfehler die Meldung nicht versehentlich dauerhaft macht.
    private static func parseDeadline(_ text: String) -> Date? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        for format in ["dd.MM.yyyy", "yyyy-MM-dd"] {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = format
            if let date = formatter.date(from: trimmed) {
                return Calendar.current.startOfDay(for: date)
            }
        }
        return nil
    }

    /// Ein Datum als Tages-Text, z. B. „2026-07-14“ (für den Vergleich
    /// „wurde heute schon bestätigt?“).
    private static func dayString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
