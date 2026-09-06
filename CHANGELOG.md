# Changelog — RezeptWerk

Die Versionsgeschichte der App. Die passenden „Was ist neu“-Texte für
App Store Connect stehen in `AppStore-Texte.md`.

## Version 2.2 (in Arbeit)

**Neue Funktionen**

- **Portionen im Wochenplan**: Beim Einplanen lässt sich die Portionszahl
  einstellen — „wie im Rezept“ oder eine feste Zahl, die gemerkt wird,
  weil sie meist dem Haushalt entspricht. Am geplanten Gericht steht die
  Zahl in einer Kapsel und lässt sich antippen und ändern. Wer ein
  Gericht aus dem Plan öffnet, bekommt den Portionsrechner gleich passend
  eingestellt.
- **Portionen wirken jetzt überall**: Das Zutaten-Blatt im Kochmodus und
  „Zur Einkaufsliste“ rechnen mit den Portionen aus dem Portionsrechner;
  „Aus Wochenplan übernehmen“ rechnet jedes Gericht auf seine geplanten
  Portionen um. Vorher galten dort immer die Originalmengen des Rezepts.
- **Hilfe aktualisiert**: Kochmodus, Wochenplan und Einkaufsliste
  erklären die neuen Möglichkeiten.

**Technik**

- `PlannedMeal.servings` (0 = wie im Rezept; additive Migration) mit
  `effectiveServings`/`scaleFactor`; `Recipe.scaleFactor(forServings:)`
  als gemeinsame Umrechnung für Portionsrechner, Kochmodus und
  Einkaufsliste; `CookingModeViewModel(recipe:servings:)`;
  `ShoppingListService.add(recipe:servings:)`; neues `MealServingsSheet`.
- Aus dem Wochenplan wird über den Planeintrag navigiert
  (`navigationDestination(for: PlannedMeal.self)` in Dashboard- und
  iPad-Stack), damit die Detailansicht die geplanten Portionen kennt.
- Unit-Tests von 47 auf 55 erweitert (Portionsumrechnung,
  Wochenplan-Portionen).

## Version 2.1 (Juli 2026)

**Neue Funktionen**

- **Pökel-Rechner** (Werkzeuge): fürs Nasspökeln — Fleischgewicht und
  Wassermenge eingeben (mit 40-%-Vorschlag), Lakenstärke per Schnellwahl
  (6/8/10/12 %) oder frei, optional Zucker. Ergebnis: NPS-Menge gesamt
  und je Liter, Pökelzeit-Faustformel nach der dicksten Stelle des
  Fleischs samt Durchbrennen-Hinweis. Eingaben werden gemerkt;
  Richtwerte anpassbar in `Views/Tools/PoekelRechnerView.swift`.
- **Maß-Umrechner** (Werkzeuge): amerikanische Rezept-Angaben in
  deutsche Maße — Cup, tbsp, tsp und fl oz zutatengenau in Gramm
  (16 Dichte-Richtwerte), Unzen und Pfund in Gramm, Fahrenheit ↔
  Celsius samt Gasherd-Stufen-Referenz. Werte anpassbar in
  `Views/Tools/UmrechnerData.swift`.
- **„Kochen mit ReiMa“ verlinkt**: neue Karte auf der Startseite und
  eigener Bereich in den Einstellungen mit kurzer Vorstellung der
  Webseite — ein Tipp öffnet kochenmitreima.de im Browser.
- **Hilfe-Thema „Werkzeuge“**: Die In-App-Anleitung erklärt jetzt alle
  vier Werkzeuge (auch Kerntemperaturen und Wurst-Rechner).

**Fehlerbehebungen & Feinschliff**

- **Rezept-Empfang ohne Kategorie-Duplikate**: Beim Öffnen einer
  `.rezeptwerk`-Datei wird eine vorhandene Kategorie wiederverwendet
  (Groß-/Kleinschreibung egal); unbekannte Kategorien entstehen erst
  beim Speichern — Abbrechen hinterlässt nichts mehr. Der Editor weist
  auf Kategorien hin, die beim Speichern neu angelegt werden.
- **Speicherfehler weiter abgesichert**: Auch der Rezept-Editor, das
  Löschen von Rezepten und die Koch-Notiz der Kochmodus-Abschlussseite
  nehmen fehlgeschlagene Änderungen jetzt zurück und melden sich —
  nichts geht mehr still verloren.
- **Geöffnete Rezept-Dateien belegen keinen Speicher mehr**:
  `.rezeptwerk`-Dateien werden direkt an ihrem Ort gelesen, statt dass
  iOS bei jedem Öffnen eine unsichtbare Kopie im App-Ordner ablegt.

**Technik**

- `LSSupportsOpeningDocumentsInPlace` in der Info.plist (behebt zugleich
  die Xcode-Warnung zum Datei-Öffnen).
- Vorgemerkte Kategorien aus empfangenen Dateien
  (`RecipeDraft.pendingCategoryName`) werden zentral in
  `RecipeImportService.save` aufgelöst; der Kochmodus stellt den Timer
  zentral über `stepIndex.didSet` um.
- Unit-Tests von 35 auf 47 erweitert (Umrechner- und Pökel-Mathematik).
  Test-Stabilität: Die In-Memory-Container der Tests werden am Leben
  gehalten — `mainContext` hält seinen Container nicht stark; seit
  OS 26.5 stürzten die Test-Suiten sonst ab.

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

**Technik**

- `RecipeStep.imageData` (extern gespeichert, additive Migration);
  Backup-Format um optionales Schrittbild erweitert (abwärtskompatibel).
- Eigener Dateityp `de.rezeptwerk.app.recipe` + `onOpenURL`-Empfang.
- `TimerNotificationService` (lokale Mitteilungen, fester Kennzeichner,
  Stornierung bei Pause/Reset/Schrittwechsel).

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

**Technik**

- Neues Datenmodell `CookingNote` (additiv, leichte Migration —
  bestehende Daten bleiben erhalten).
- `WidgetPlanSync` schreibt den Wochenplan-Schnappschuss in die
  App-Gruppe (beim Planen, Entfernen und App-Aktivieren).
- Einmaliger Einrichtungsschritt fürs Widget auf echten Geräten:
  App-Groups-Capability für das Widget-Ziel (siehe ANLEITUNG.md).

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
