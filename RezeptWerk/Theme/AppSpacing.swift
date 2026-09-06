import SwiftUI

/// Zentrale Abstände und Radien.
///
/// Einheitliche Abstände sind das halbe Design: Statt überall „magische
/// Zahlen“ zu verteilen, nutzen alle Views diese Konstanten. Das hält die
/// Oberfläche ruhig und lässt sich später an einer Stelle anpassen.
enum AppSpacing {

    /// 4 pt — minimaler Abstand (z. B. zwischen Icon und Text in Pills).
    static let xs: CGFloat = 4

    /// 8 pt — kleiner Abstand.
    static let s: CGFloat = 8

    /// 12 pt — mittlerer Abstand (Standard innerhalb von Karten).
    static let m: CGFloat = 12

    /// 16 pt — großer Abstand (zwischen Elementen).
    static let l: CGFloat = 16

    /// 24 pt — sehr großer Abstand (zwischen Abschnitten).
    static let xl: CGFloat = 24

    /// 32 pt — Abschnittstrennung auf ruhigen Bildschirmen.
    static let xxl: CGFloat = 32

    /// Außenabstand der Bildschirminhalte zum Rand.
    static let screen: CGFloat = 20
}

/// Zentrale Eckenradien.
enum AppRadius {

    /// Karten und große Flächen.
    static let card: CGFloat = 22

    /// Buttons.
    static let button: CGFloat = 14

    /// Kleine Elemente: Thumbnails, Eingabefelder, Symbol-Quadrate.
    static let small: CGFloat = 12
}
