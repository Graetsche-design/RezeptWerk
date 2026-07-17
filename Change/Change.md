# Changelog — RezeptWerk

Die Versionsgeschichte der App. Die passenden „Was ist neu“-Texte für
App Store Connect stehen in `AppStore-Texte.md`.

## Version 2.0 (Juli 2026)

**Neue Funktionen**

- **Timer-Mitteilungen**: Der Kochmodus-Timer klingelt jetzt auch, wenn
  die App im Hintergrund ist oder das iPhone gesperrt wurde (lokale
  Mitteilung mit Ton; Erlaubnis wird beim ersten Timer-Start erfragt).
- **Rezepte tauschen**: „Als RezeptWerk-Datei teilen“ erzeugt eine
  `.rezeptwerk`-Datei für WhatsApp, Mail oder das Forum. Wer RezeptWerk
  hat, tippt die Datei an und bekommt das Rezept als Editor-Vorschau —
  mit Bildern, Schritt-Fotos und Wurst-Fachdaten. Bewertung, Favorit
  und Koch-Notizen bleiben beim Teilen privat.
- **Foto je Zubereitungsschritt**: Im Editor pro Schritt wählbar, in
  der Detailansicht und groß im Kochmodus sichtbar, im Backup enthalten.

**Fundament**

- **Git-Versionsverwaltung** eingerichtet (mit .gitignore); jede
  Ausbaustufe ist als eigener Commit nachvollziehbar.
- **Unit-Test-Ziel `RezeptWerkTests`** (Swift Testing, gut 30 Tests):
  Text-Parser, Zahlformate, Wurst-Rechner-Mathematik, Backup-Roundtrip
  samt Duplikat-Regression und Alt-Format, Einkaufslisten-Zusammen-
  fassung, Timer-Logik, Rezept-Tausch.
- **Speicherfehler sichtbar**: Schlägt das Speichern fehl (z. B. voller
  Gerätespeicher), wird die Änderung zurückgerollt und ein Hinweis
  gezeigt, statt still Daten zu verlieren — an acht wichtigen Stellen.


## Version 1.5 (Juli 2026)

**Neue Funktionen**

- **Werkzeuge** (neuer Bereich auf dem Start-Tab):
  - **Kerntemperatur-Spickzettel** — Offline-Nachschlagetabelle mit Suche:
    Rind, Schwein, Geflügel, Lamm & Wild, Fisch, Wurst & Räuchern, inkl.
    Sicherheitshinweisen. Werte anpassbar in
    `Views/Tools/KerntemperaturData.swift`.
  - **Wurst-Rechner** — Fleisch-Mix aus mehreren Sorten (Gewicht je Sorte,
    Anteil in Prozent), Zutaten je Kilogramm, alle Mengen live
    hochgerechnet. Vorlagen für Brühwurst, Rohwurst und Rohschinken.
    Fleisch- und Zutatenliste werden gemerkt.
  - **Als Rezept speichern** — der Rechner-Stand wird auf Knopfdruck ein
    richtiges Rezept: Fleisch-Mix + berechnete Mengen als Zutatenliste,
    Fachdaten (Fleischmenge, NPS und Gewürze je kg), Kategorie
    „Wurst & Räuchern“.
- **Koch-Notizen (Kochjournal)** — datierte Notizen pro Rezept
  („nächstes Mal weniger Salz“): auf der Abschlussseite des Kochmodus
  oder per „Hinzufügen“ in der Detailansicht. Im Backup enthalten;
  ältere Backups bleiben lesbar.
- **Homescreen-Widget** „Heute auf dem Wochenplan“ (klein + mittel) —
  zeigt die heute geplanten Mahlzeiten, wechselt um Mitternacht
  selbstständig auf den nächsten Tag. Neues Xcode-Ziel
  `RezeptWerkWidget`; Daten via App-Gruppen-Schnappschuss.
- **„Bildschirm immer an“** (Einstellungen → Bildschirm): Der Bildschirm
  wird nicht mehr automatisch dunkel, solange RezeptWerk geöffnet ist —
  praktisch in der Küche. Der Kochmodus hält den Bildschirm weiterhin
  immer wach, unabhängig vom Schalter.

**Fehlerbehebungen & Feinschliff**

- **Backup-Wiederherstellung abgesichert**: Bei zwei gleichnamigen
  Kategorien (konnte durch iCloud-Duplikate vorkommen) stürzte die
  Wiederherstellung ab — jetzt nicht mehr.
- **Kochmodus-Timer rechnet mit echter Uhrzeit**: Nach einem kurzen
  Wechsel in eine andere App zeigt der Timer sofort wieder die korrekte
  Restzeit (vorher „fror“ er ein und lief entsprechend zu spät ab).
- **Größere Tippflächen** im Kochmodus-Kopf (44 × 44 Punkte,
  Apple-Empfehlung) — besser bedienbar mit nassen Händen.


## Version 1.4 (Juli 2026)

- **Ankündigungs-Hinweis**: Die App lädt beim Start eine kleine
  JSON-Datei vom eigenen Server (kochenmitreima.de) und zeigt Meldungen
  des Entwicklers als Hinweisfenster mit „Verstanden“-Knopf — z. B.
  „vor dem Update bitte Backup erstellen“. Optionales `bis`-Datum:
  bis dahin erscheint die Meldung täglich erneut, danach endet sie von
  selbst. Ohne Push-Dienst, ohne Drittanbieter.

## Version 1.0 (Juni 2026)

- Erstveröffentlichung: Rezeptverwaltung mit Kategorien, Tags und
  Portionsrechner · Wurst-&-Räucher-Fachdaten · Import per Foto (OCR),
  PDF, Webseite und Zwischenablage · Kochmodus · Wochenplaner ·
  Einkaufsliste · Teilen-Erweiterung · PDF-Export · iCloud-Sync
  (optional) · Backup & Wiederherstellen · In-App-Hilfe ·
  animierter Splashscreen.
