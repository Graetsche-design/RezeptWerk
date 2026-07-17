import Foundation
import SwiftData

/// Fachdaten für Wurst- und Räucherrezepte.
///
/// Diese Felder existieren bewusst als eigenes Modell mit 1:1-Beziehung
/// zum Rezept: Normale Rezepte bleiben schlank (`sausageDetails == nil`),
/// und der Fachdaten-Block erscheint nur dort, wo er sinnvoll ist.
///
/// Fast alle Felder sind optional bzw. Freitext — beim Wursten haben
/// Hobby-Metzger sehr unterschiedliche Arbeitsweisen, deshalb zwingt die
/// App hier zu nichts.
@Model
final class SausageSmokingDetails {

    // MARK: Rohmaterial & Würzung

    /// Fleischmenge in Kilogramm.
    var meatWeightKg: Double?

    /// Gewürze pro kg als Freitext, z. B.
    /// „18 g Salz, 3 g Pfeffer, 2 g Majoran, 1 g Knoblauchpulver“.
    var seasoningPerKg: String = ""

    /// Nitritpökelsalz in Gramm pro kg (üblich: 18–22 g/kg, je nach Rezept).
    var npsGramsPerKg: Double?

    /// Kutterhilfsmittel (Art und Menge), z. B. „3 g/kg Diphosphat“.
    var cutterAids: String = ""

    /// Schüttung/Eiswasser in Prozent der Fleischmenge, z. B. 20.
    var iceWaterPercent: Double?

    // MARK: Darm & Kaliber

    /// z. B. „Schweinedarm, Kaliber 28/30“.
    var casing: String = ""

    // MARK: Räuchern

    var smokingMethodRaw: String = SmokingMethod.none.rawValue

    /// Räucherzeit in Minuten (bei Kalträuchern gern mehrere Durchgänge —
    /// dann die Gesamtzeit eintragen und Details in die Notizen schreiben).
    var smokingTimeMinutes: Int?

    /// Räuchertemperatur in °C.
    var smokingTemperatureCelsius: Int?

    // MARK: Brühen & Garen

    /// Brühtemperatur in °C (klassisch: 76–80 °C).
    var scaldingTemperatureCelsius: Int?

    /// Ziel-Kerntemperatur in °C (z. B. Brühwurst: 72 °C).
    var coreTemperatureCelsius: Int?

    // MARK: Reifung & Trocknung

    /// Reifezeit in Tagen (Rohwurst, Schinken).
    var curingDays: Int?

    /// Trocknungszeit in Tagen.
    var dryingDays: Int?

    // MARK: Sicherheit

    /// Hinweise zu Sicherheit und Hygiene — wird in der Detailansicht
    /// hervorgehoben dargestellt.
    var safetyNotes: String = ""

    /// Rückverweis aufs Rezept. Die `inverse`-Deklaration liegt bei `Recipe`.
    var recipe: Recipe?

    init() {}

    var smokingMethod: SmokingMethod {
        get { SmokingMethod(rawValue: smokingMethodRaw) ?? .none }
        set { smokingMethodRaw = newValue.rawValue }
    }

    /// `true`, wenn mindestens ein Feld ausgefüllt ist — sonst zeigt die
    /// Detailansicht den Block gar nicht erst an.
    var hasAnyValue: Bool {
        meatWeightKg != nil
            || !seasoningPerKg.isEmpty
            || npsGramsPerKg != nil
            || !cutterAids.isEmpty
            || iceWaterPercent != nil
            || !casing.isEmpty
            || smokingMethod != .none
            || smokingTimeMinutes != nil
            || smokingTemperatureCelsius != nil
            || scaldingTemperatureCelsius != nil
            || coreTemperatureCelsius != nil
            || curingDays != nil
            || dryingDays != nil
            || !safetyNotes.isEmpty
    }
}
