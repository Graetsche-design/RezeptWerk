import Foundation

/// Liest, was die Teilen-Erweiterung über die App-Gruppe hinterlegt hat.
///
/// Die Erweiterung (`RezeptWerkShare`) legt geteilten Text oder Links in der
/// gemeinsamen App-Gruppe ab. Beim Öffnen/Aktivieren der App holt die
/// `RootView` den Eintrag hier ab und übergibt ihn an den Import-Ablauf.
enum SharedImportInbox {

    /// Muss mit der App-Gruppe in den Entitlements übereinstimmen.
    static let appGroupID = "group.de.rezeptwerk.app"

    private static let kindKey = "pendingShareKind"
    private static let contentKey = "pendingShareContent"
    private static let dateKey = "pendingShareDate"

    /// Ein wartender geteilter Inhalt.
    struct Pending: Identifiable {
        let id = UUID()
        /// "url" oder "text".
        let kind: String
        let content: String
    }

    /// Holt einen wartenden Eintrag und **entfernt** ihn (damit er nicht
    /// doppelt verarbeitet wird). Gibt `nil` zurück, wenn nichts wartet.
    static func take() -> Pending? {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let kind = defaults.string(forKey: kindKey),
              let content = defaults.string(forKey: contentKey),
              !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return nil }

        defaults.removeObject(forKey: kindKey)
        defaults.removeObject(forKey: contentKey)
        defaults.removeObject(forKey: dateKey)

        return Pending(kind: kind, content: content)
    }
}
