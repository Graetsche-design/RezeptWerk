# RezeptWerk

Dein digitales Rezept-Werkzeug — fürs Kochen, Grillen, Wursten und Räuchern.
Rustikal, warm, handwerklich. iPhone & iPad, 100 % lokal, kein Backend.

> **Einsteiger?** Lies zuerst die [ANLEITUNG.md](ANLEITUNG.md) — sie erklärt
> Schritt für Schritt, wie du die App öffnest, startest und testest.
> Dieses README beschreibt die Technik dahinter.

---

## Funktionsumfang

- **Animierter Splashscreen**: dunkler Anthrazit-Verlauf (nahtlos ab dem
  Launchscreen, kein weißes Aufblitzen), kupfernes Serifen-„R“ mit
  metallischem Glanz, aufziehender Unterstrich-Balken, aufsteigende
  Glut-Funken, Wortmarke + Claim; respektiert „Bewegung reduzieren“.
  Rein visuell — die App-Logik bleibt unverändert in `RootView`.
- **Dashboard** mit Begrüßung, Suche, Favoriten- und „Zuletzt hinzugefügt“-
  Karussells, Kategorienübersicht und Schnellzugriffen.
- **Rezeptübersicht**: Kartenliste (iPhone) / Grid (iPad), Volltextsuche
  über Titel, Zutaten, Tags, Notizen und Kategorie; Filter nach Kategorie,
  Unterkategorie, Tags, Schwierigkeit und Favoriten; Sortierung.
- **Rezeptdetails**: Bild, Bewertung (antippbar), Info-Pills, Tags,
  Zutaten mit **Portionsrechner**, nummerierte Schritte, Notizen, Quelle
  (mit Link), Verwaltungsdaten („zuletzt gekocht“).
- **Editor** in klaren Abschnitten — derselbe Editor dient für Neuanlage,
  Bearbeitung und Import-Korrektur. Mehrere Bilder (komprimiert), Tags mit
  Wiederverwendung, Timer pro Schritt.
- **Wurst & Räuchern**: eigener Fachdaten-Block (Fleischmenge, Gewürze/kg,
  NPS g/kg, Kutterhilfsmittel, Schüttung, Darm/Kaliber, Räucherart/-zeit/
  -temperatur, Brüh- und Kerntemperatur, Reife- und Trocknungszeit,
  Sicherheits- & Hygienehinweise). Erscheint nur, wo er hingehört.
- **Import**: Foto (Mediathek + Kamera-Dokumentenscanner), PDF (Text und
  Scan-OCR), Webseite (schema.org/JSON-LD mit Text-Fallback),
  Zwischenablage. Alles mündet in einer **Import-Vorschau** mit
  Originaltext und Korrektur im Editor vor dem Speichern.
- **Kochmodus**: Vollbild, immer dunkel (blendfrei am Herd), ein Schritt
  pro Seite (mit Schritt-Foto, falls vorhanden), einstellbare Großschrift,
  abhakbare Zutaten (Mengen für die gewählten Portionen aus Portionsrechner
  oder Wochenplan), Timer mit Fortschrittsring und Haptik — der auch
  **außerhalb der App klingelt** (lokale Mitteilung bei Hintergrund/
  Sperrbildschirm), Bildschirm bleibt an, Abschluss-Seite mit Bewertung
  und optionaler Koch-Notiz.
- **Foto je Zubereitungsschritt**: im Editor pro Schritt wählbar
  (komprimiert, extern gespeichert), sichtbar in Detailansicht und
  Kochmodus, im Backup enthalten.
- **Rezepte tauschen (.rezeptwerk)**: jedes Rezept als kleine Datei
  teilen (WhatsApp, Mail, Forum) — Empfänger mit RezeptWerk tippen die
  Datei an und bekommen das Rezept als Editor-Vorschau, inklusive Bildern
  und Fachdaten. Bewertung, Favorit und Koch-Notizen bleiben privat.
  Eigener Dateityp `de.rezeptwerk.app.recipe`, Empfang via `onOpenURL`.
- **Koch-Notizen (Kochjournal)**: datierte Notizen pro Rezept („12.07.:
  nächstes Mal weniger Salz“) — auf der Kochmodus-Abschlussseite oder per
  „Hinzufügen“ in der Detailansicht; im Backup enthalten.
- **Werkzeuge** (Dashboard-Bereich): **Kerntemperatur-Spickzettel**
  (Offline-Nachschlagetabelle mit Suche — Rind, Schwein, Geflügel, Lamm &
  Wild, Fisch, Wurst & Räuchern) und **Wurst-Rechner** (Fleisch-Mix aus
  mehreren Sorten mit Prozent-Anteilen, Zutaten je kg, Gesamtmengen live;
  Vorlagen für Brühwurst/Rohwurst/Rohschinken, Listen werden gemerkt).
  Der Rechner-Stand lässt sich **als Rezept speichern** — inklusive
  berechneter Zutatenliste und Fachdaten, einsortiert in
  „Wurst & Räuchern“. Dazu der **Pökel-Rechner** fürs Nasspökeln
  (Lakenstärke mit Schnellwahl 6/8/10/12 %, NPS-Menge in Gramm, optional
  Zucker, Pökelzeit-Faustformel nach Fleischdicke plus
  Durchbrennen-Hinweis; Eingaben werden gemerkt) und der
  **Maß-Umrechner** (Cups/EL/TL zutatengenau in Gramm über
  Dichte-Richtwerte, Unzen/Pfund in Gramm, °F ↔ °C samt
  Gasherd-Stufen-Referenz).
- **Homescreen-Widget** „Heute auf dem Wochenplan“ (klein + mittel):
  zeigt die heute geplanten Mahlzeiten im RezeptWerk-Look; wechselt um
  Mitternacht selbstständig auf den nächsten Tag. Eigenes Target
  `RezeptWerkWidget`, Daten via App-Gruppen-Schnappschuss
  (`App/WidgetPlanSync`) — die Datenbank bleibt privat.
- **Kategorien**: 12 Standard-Kategorien mit Unterkategorien, eigene
  Kategorien/Unterkategorien anlegbar.
- **Wochenplaner**: Rezepte tageweise zu Mahlzeiten (Frühstück/Mittag/
  Abend/Snack) einplanen, Wochen vor-/zurückblättern, „Heute"-Markierung.
  Auf dem iPhone über die Dashboard-Karte „Wochenplan" (zeigt die heute
  geplanten Gerichte), auf dem iPad als eigener Sidebar-Tab. Jedes Rezept
  kann im Editor unter „Geeignet für" markiert werden, zu welchen
  Mahlzeiten es passt (Mehrfachauswahl); beim Einplanen werden passende
  Rezepte oben mit „Geeignet"-Badge angezeigt (plus Filter „Nur passende").
  **Portionen je Planeintrag**: beim Einplanen „wie im Rezept" oder eine
  feste, gemerkte Zahl; am Gericht als Kapsel antippbar und änderbar. Ein
  aus dem Plan geöffnetes Rezept startet mit diesen Portionen — Kochmodus
  und Einkaufsliste rechnen damit.
- **Einkaufsliste**: Zutaten aus dem Wochenplan (laufende Woche, jedes
  Gericht mit seinen geplanten Portionen) oder aus einzelnen Rezepten
  (umgerechnet auf die Portionen im Portionsrechner) übernehmen — gleiche
  Zutaten werden automatisch zusammengefasst (2× „200 g Mehl" →
  „400 g Mehl"). Eigene Einträge hinzufügen, abhaken, erledigte/alle
  löschen; die offene Liste als Text **teilen** (WhatsApp, Nachrichten,
  Mail, Erinnerungen). Auf dem iPhone über die Dashboard-Karte, auf dem
  iPad als Sidebar-Tab; auch aus dem Wochenplan und der
  Rezept-Detailansicht erreichbar.
- **iCloud-Synchronisierung** (optional, abschaltbar): echte automatische
  Sync über alle Geräte mit derselben Apple-ID (SwiftData + CloudKit).
  Standardmäßig AUS; einmalige Einrichtung der iCloud-Capability in Xcode
  nötig (siehe unten). Fällt bei fehlender Einrichtung automatisch auf
  lokalen Speicher zurück — die App startet immer.
- **Backup & Wiederherstellen**: alle Rezepte (inkl. Bilder, Kategorien,
  Tags, Fachdaten) als eine JSON-Datei sichern — über die Dateien-App in
  **Google Drive, iCloud Drive, Dropbox** … und von dort wiederherstellen
  (Zusammenführen oder Ersetzen). Kein Konto, kein Drittanbieter-SDK.
- **Ankündigungs-Hinweis**: der Entwickler kann allen Nutzern eine Meldung
  anzeigen (z. B. „vor dem Update bitte Backup erstellen“) — die App lädt
  beim Start eine kleine JSON-Datei vom eigenen Server (Vorlage in
  `Server/`, Einrichtung siehe ANLEITUNG.md) und zeigt sie als Hinweis-
  fenster mit „Verstanden“-Knopf. Optionales `bis`-Datum: bis dahin
  erscheint die Meldung täglich erneut, danach endet sie von selbst.
  Ohne Push-Dienst, ohne Drittanbieter; ist die Datei leer oder nicht
  erreichbar, passiert nichts.
- **Teilen & Export**: jedes Rezept als **PDF** (hochwertiges Kochbuch-
  Layout im RezeptWerk-Stil, mehrseitig, mit Titelbild) oder als
  **Klartext** teilen — über das System-Teilen-Menü (Mail, Nachrichten,
  WhatsApp, „In Dateien sichern“ …), mit Live-PDF-Vorschau. Erreichbar
  über den Teilen-Knopf in der Rezept-Detailansicht.
- **Teilen-Erweiterung (Share Extension)**: RezeptWerk erscheint im
  iOS-Teilen-Menü. Aus Safari, Notizen, Nachrichten (oder Instagram – mit
  den bekannten Grenzen, siehe unten) auf „Teilen → RezeptWerk“ tippen; der
  geteilte Link/Text landet über eine App-Gruppe in der App und wird beim
  nächsten Öffnen automatisch durch den Import-Ablauf geschickt (Vorschau →
  speichern). Eigenes Xcode-Ziel `RezeptWerkShare`.
- **Anleitung & Hilfe (in der App)**: ein durchsuchbarer Hilfe-Bereich
  (Einstellungen → ganz oben) mit 14 Themen, die jede Funktion erklären —
  Themenübersicht mit Suche → gut gesetzte Detailseite je Thema.
- **Einstellungen**: Erscheinungsbild, „Bildschirm immer an“ (Bildschirm
  wird nicht dunkel, solange die App geöffnet ist), Kochmodus-Schriftgröße,
  Beispielrezepte neu laden (eigene Rezepte bleiben unberührt),
  Import-Tipps, App-Info — und der Bereich „Kochen mit ReiMa“ mit einer
  kurzen Vorstellung der Webseite kochenmitreima.de samt Link dorthin.
- **6 Beispielrezepte** inkl. Käsekrakauer mit komplettem Fachdaten-Block
  und Steak mit Schritt-Timern.

## Technik-Eckdaten

| | |
|---|---|
| Sprache / UI | Swift (Sprachmodus 5) / SwiftUI |
| Persistenz | SwiftData, Bilder via `.externalStorage` |
| Minimum | iOS / iPadOS 18 |
| Xcode | 16 oder neuer (entwickelt & getestet mit 26.5) |
| Abhängigkeiten | **Keine** — nur Apple-Frameworks |
| Frameworks | SwiftUI, SwiftData, PhotosUI, Vision (OCR), VisionKit (Scanner), PDFKit, UniformTypeIdentifiers |
| Berechtigungen | Nur Kamera (Dokumentenscanner); Fotoauswahl braucht keine |

Es gibt genau **zwei bewusste UIKit-Stellen** (kommentiert):
die Serifenschrift der Navigationsleiste (`AppTheme`) und das
Bildschirm-Wachhalten im Kochmodus (`isIdleTimerDisabled`) — plus die
unvermeidbare `UIViewControllerRepresentable`-Hülle um Apples
Dokumentenscanner.

## Architektur

**MVVM light** — ViewModels nur dort, wo echte Logik steckt:

```
                    ┌──────────────────────────────────────────────┐
  Foto ──► OCRService ─┐                                           │
  PDF ──► PDFImport…  ─┤   ParsedRecipe        RecipeDraft         │
  Web ──► WebRecipe…  ─┼──► (Übergabe-  ──►  (bearbeitbare   ──►  RecipeImportService
  Text ─► Clipboard…  ─┘     format)           Arbeitskopie)       .save(draft:…)
                              │                    ▲                    │
                              ▼                    │                    ▼
                       ImportPreviewView ──► RecipeEditorView      SwiftData
                                                                  (lokale DB)
```

Die drei tragenden Ideen:

1. **`RecipeDraft`** (`ViewModels/`): die bearbeitbare Arbeitskopie eines
   Rezepts. Editor und alle vier Import-Wege arbeiten darauf. Abbrechen ist
   immer gefahrlos; gespeichert wird an genau einer Stelle
   (`RecipeImportService.save`), wo der Draft in SwiftData-Objekte
   übersetzt wird (Kinder werden dabei komplett ersetzt — die einfachste
   fehlersichere Strategie; Tags werden case-insensitiv wiederverwendet).
2. **`ParsedRecipe`** (`Services/Import/`): das `Sendable`-Übergabeformat
   aller Import-Services — inklusive `rawText` für die ehrliche Vorschau.
3. **`RecipeTextParser`** (`Utilities/`): die gemeinsame Heuristik hinter
   OCR-, PDF- und Zwischenablage-Import (Abschnitts-Überschriften,
   Mengenzeilen, nummerierte Schritte, Portionen, Zeiten). Ausführlich
   kommentiert und an einer Stelle erweiterbar.

Einfache Listen nutzen `@Query` direkt in der View (SwiftData-Best-
Practice). Gefiltert wird **im Speicher** (`RecipeFilter`): bei einer
persönlichen Sammlung verzögerungsfrei und es umgeht die bekannten
`#Predicate`-Stolperfallen mit optionalen Beziehungen und n:m-Tags.

### Datenmodell

```
Recipe ──┬─ [Ingredient]           Menge · Einheit · Name · Reihenfolge
         ├─ [RecipeStep]           Text · Reihenfolge · timerSeconds
         ├─ [RecipeImage]          Bilddaten (.externalStorage)
         ├─ RecipeCategory?  ───── hat [RecipeSubcategory] (cascade)
         ├─ RecipeSubcategory?
         ├─ [RecipeTag]            n:m, Wiederverwendung beim Speichern
         ├─ [PlannedMeal]          Wochenplan-Einträge (Datum · Mahlzeit)
         ├─ [CookingNote]          datierte Koch-Notizen (Kochjournal)
         └─ SausageSmokingDetails? 1:1, nur bei Wurst-/Räucherrezepten
```

SwiftData-Regeln, die hier konsequent eingehalten werden (häufigste
Fehlerquellen): `inverse:` nur auf **einer** Seite jeder Beziehung;
`sortIndex` + `sorted…`-Properties, weil SwiftData-Arrays unsortiert sind;
Enums als Rohwert gespeichert (`difficultyRaw`); Löschregeln: Rezept-Kinder
`cascade`, Kategorien `nullify` (Rezepte überleben das Löschen ihrer
Kategorie).

## Projektstruktur

```
Rezepteapp/
├── RezeptWerk.xcodeproj          Xcode-Projekt (synchronisierte Ordner:
│                                 neue Dateien sind automatisch im Build)
├── ANLEITUNG.md                  Einsteiger-Anleitung
├── README.md                     dieses Dokument
└── RezeptWerk/
    ├── App/                      RezeptWerkApp (@main, DB, Seeding) ·
    │                             RootView (Tabs/Sidebar) · AppTab ·
    │                             ModelContainerFactory (lokal/iCloud) ·
    │                             WidgetPlanSync (Schnappschuss fürs Widget)
    ├── Models/                   10 SwiftData-Modelle + Difficulty + SmokingMethod
    ├── ViewModels/               RecipeDraft · ImportViewModel · CookingModeViewModel
    ├── Views/
    │   ├── Launch/               LaunchRootView · SplashView (animierter Start)
    │   ├── Dashboard/            DashboardView · GreetingHeader · QuickActions
    │   ├── Recipes/              RecipeListView · RecipeFilter(+Sheet)
    │   ├── RecipeDetail/         Detail · Zutaten(+Portionsrechner) · Schritte · Fachdaten
    │   ├── RecipeEditor/         Editor · Zutaten-/Schritt-Listen · Tags · Fachdaten
    │   ├── Planner/              WeekPlannerView · PlanMealSheet (Wochenplan)
    │   ├── ShoppingList/         ShoppingListView (Einkaufsliste)
    │   ├── CookingMode/          Kochmodus · Schritt-Seite · Zutaten-Sheet · Timer
    │   ├── Import/               Hub · Foto/Scanner · PDF · Web · Text · Vorschau
    │   ├── Categories/           Übersicht · Kategorie-Rezepte · Kategorie-Editor
    │   ├── Help/                 HelpView · HelpTopicDetailView · HelpContent (In-App-Anleitung)
    │   ├── Tools/                Kerntemperatur-Spickzettel · Wurst-Rechner
    │   ├── Favorites/            FavoritesView
    │   └── Settings/             SettingsView
    ├── Services/
    │   ├── Announcement/         AnnouncementService (Meldung an alle Nutzer)
    │   ├── Share/                RecipeShareService (Rezept-Tausch .rezeptwerk)
    │   ├── Notifications/        TimerNotificationService (Timer klingelt überall)
    │   ├── Backup/               BackupModels · BackupService · BackupFileDocument
    │   ├── ShoppingList/         ShoppingListService (Zutaten zusammenfassen)
    │   ├── Export/               RecipeExportService (Text + PDF via WebKit)
    │   ├── Import/               ParsedRecipe · ImportError · RecipeImportService
    │   ├── OCR/                  OCRService (Vision, de+en)
    │   ├── PDF/                  PDFImportService (PDFKit + OCR-Fallback)
    │   ├── WebParser/            WebRecipeParserService · SchemaOrgRecipeParser
    │   └── ClipboardParser/      ClipboardRecipeParserService
    ├── Utilities/                RecipeTextParser · FormatHelpers · AppSettings ·
    │                             ImageCompressor · PreviewSupport
    ├── Theme/                    AppTheme · AppColors · AppTypography ·
    │                             AppSpacing · CardStyles · ButtonStyles
    ├── Components/               15 wiederverwendbare Bausteine (Karten, Sterne,
    │                             Chips, FlowLayout, Leerzustände, Fotoauswahl …)
    ├── SampleData/               DefaultCategories · SampleRecipes · SampleDataService
    └── Assets.xcassets/          App-Icon · 9 Farb-Sets (je hell/dunkel)

Server/                             Vorlage der Ankündigungs-Datei für den
                                    eigenen Webspace (rezeptwerk-ankuendigung.json)
RezeptWerk.entitlements             iCloud/CloudKit + App-Gruppe (Projektwurzel)
RezeptWerkShare/                    Teilen-Erweiterung (ShareViewController)
RezeptWerkShare-Info.plist          NSExtension-Konfiguration der Erweiterung
RezeptWerkShare.entitlements        App-Gruppe der Erweiterung
RezeptWerkWidget/                   Homescreen-Widget (Zeitachse, Ansicht, Farben)
RezeptWerkWidget-Info.plist         WidgetKit-Konfiguration des Widgets
RezeptWerkWidget.entitlements       App-Gruppe des Widgets
RezeptWerkTests/                    Unit-Tests (Swift Testing): Parser, Rechner,
                                    Backup-Roundtrip, Einkaufsliste, Timer, Tausch
```

## Teilen-Erweiterung einrichten (einmalig)

Damit „Teilen → RezeptWerk“ funktioniert, müssen App **und** Erweiterung
dieselbe App-Gruppe nutzen. Die Berechtigungen liegen schon in den
`*.entitlements`-Dateien; in Xcode noch aktivieren:

1. Target **RezeptWerk** → **Signing & Capabilities** → **+ Capability →
   App Groups** → die Gruppe **`group.de.rezeptwerk.app`** ankreuzen.
2. Dasselbe für das Target **RezeptWerkShare**.
3. Beide Targets brauchen dasselbe Team (Signing). Auf dem Gerät testen:
   App starten, dann z. B. in Safari eine Rezeptseite öffnen → Teilen →
   RezeptWerk → zurück in die App wechseln → die Import-Vorschau erscheint.

**Grenzen (wie beim Web-Import):** Instagram teilt meist nur einen
**Link** zum Beitrag (hinter Login) – daraus lässt sich kein Rezept lesen.
Was funktioniert: geteilten **Text** (z. B. markierte Bildunterschrift) und
Links von echten Rezeptseiten. Reine Video-Rezepte ohne Text gehen nicht.

## Widget einrichten (einmalig, fürs echte Gerät)

Das Homescreen-Widget liest den Wochenplan-Schnappschuss über dieselbe
App-Gruppe wie die Teilen-Erweiterung. Die Berechtigung liegt schon in
`RezeptWerkWidget.entitlements`; in Xcode noch aktivieren:

1. Target **RezeptWerkWidget** → **Signing & Capabilities** →
   **+ Capability → App Groups** → **`group.de.rezeptwerk.app`** ankreuzen.
2. Im **Simulator** funktioniert das Widget auch ohne diesen Schritt.
3. Testen: App öffnen (schreibt den Schnappschuss), etwas für heute
   einplanen, dann auf dem Homescreen lange drücken → **+** → RezeptWerk.

## iCloud einrichten (einmalig, optional)

Die iCloud-Sync ist **standardmäßig aus** — die App läuft sofort lokal.
Für echte Geräte-Synchronisierung sind drei Schritte nötig
(Voraussetzung: kostenpflichtiger Apple-Developer-Account):

1. In Xcode das Target **RezeptWerk** öffnen → **Signing & Capabilities**.
2. **+ Capability → iCloud** hinzufügen, bei **Services** „CloudKit"
   ankreuzen und den Container **`iCloud.de.rezeptwerk.app`** aktivieren.
   (Die Berechtigungen liegen schon in `RezeptWerk.entitlements`.)
3. In der App: **Einstellungen → iCloud-Synchronisierung** einschalten und
   die App neu starten.

Solange Schritt 1–2 fehlen, bleibt die App lokal (der Schalter zeigt keine
Wirkung) — der Container fällt automatisch und absturzfrei auf lokalen
Speicher zurück. **Hinweis:** Das `ModelContainer`-Setup wird beim
App-Start gelesen; ein Umschalten wirkt deshalb erst nach Neustart. Auf
einem zweiten Gerät kann beim ersten Sync kurzzeitig eine doppelte
Standard-Kategorie entstehen — das ist unkritisch und einmalig löschbar.

**CloudKit-Kompatibilität des Modells:** Alle To-many-Beziehungen
(`Recipe.ingredients`, `…steps`, `…images`, `…tags`,
`RecipeCategory.subcategories`/`recipes`, `RecipeSubcategory.recipes`,
`RecipeTag.recipes`) sind **optional** (`[T]?`) — CloudKit verlangt das.
Der Zugriff läuft über die `sorted…`-/`…List`-Helfer, die immer ein
normales Array liefern. Die `remote-notification`-Background-Mode steht in
der `Info.plist`. **Während der Entwicklung** gilt: Diese Schema-Änderung
(nicht-optional → optional) kann bei einem bereits installierten Testgerät
eine Migration erfordern — im Zweifel die App einmal löschen und neu
installieren.

## Designsystem

- **Farben** (alle adaptiv hell/dunkel, zentral in `AppColors` +
  Asset-Katalog): Pergament/Creme ↔ Räucher-Anthrazit als Grund, warme
  Karten, Espresso-Text, **Kupfer als einzige Akzentfarbe**, Holzbraun für
  sekundäre Akzente.
- **Typografie** (`AppTypography`): Serifenschrift (New York) für Titel und
  Überschriften — auch in der Navigationsleiste — Systemschrift für Text;
  Dynamic-Type-fähig. Kochmodus mit eigener, einstellbarer Großschrift.
- **Handschrift der App**: Karten mit feiner Kontur und warmem Schatten,
  kupferner Unterstrich unter Abschnitts-Überschriften (auch im App-Icon),
  ruhige SF-Symbols (Flamme, Pfanne, Rauch, Ofen …). Keine Fototapeten,
  kein Kitsch.
- Der **Kochmodus** ist bewusst immer dunkel (`preferredColorScheme(.dark)`)
  — blendfrei und ruhig, alle Theme-Farben ziehen automatisch ihre
  Dunkel-Variante.

## Grenzen der MVP-Version (bewusste Entscheidungen)

| Thema | Stand | Hintergrund |
|---|---|---|
| Web-Import | Sehr gut bei Seiten mit schema.org-Daten (die große Mehrheit); Fallback: Seitentext durch den Textparser | Seiten, die Inhalte nur per JavaScript laden **und** keine strukturierten Daten einbetten, sind nicht lesbar → Umweg: Text kopieren + „Text einfügen“ |
| OCR | Sehr gut bei klarem, einspaltigem Druck | Mehrspaltige Layouts können die Zeilenreihenfolge mischen → dafür gibt es die Vorschau mit Originaltext |
| Timer | Läuft, solange die App offen ist (Bildschirm bleibt ja an) | Mitteilungen im Hintergrund sind ein V2-Thema |
| Zutaten-Parsing | Menge/Einheit-Erkennung heuristisch (deutsche Einheitenliste in `RecipeTextParser.knownUnits`, leicht erweiterbar) | Unbekannte Einheiten landen im Zutatennamen — korrigierbar im Editor |
| Sprachmodus | Swift 5 statt Swift 6 strict concurrency | Baut garantiert mit Xcode 16–26 und erspart Einsteigern kryptische Sendable-Fehler; der Code ist trotzdem modern (async/await, @Observable, @MainActor) |

## Testanleitung (Kurzfassung)

Ausführlich in der [ANLEITUNG.md](ANLEITUNG.md), Abschnitt 5.

1. **Build**: `Cmd + R` auf iPhone- und iPad-Simulator — beides wurde mit
   Xcode 26.5 gebaut und gestartet (Dashboard, Seeding, Navigation geprüft).
2. **Portionsrechner**: Steak-Rezept → Zutaten → Portionen ändern.
3. **Fachdaten**: Käsekrakauer öffnen (Fachdaten-Block + Hygiene-Box).
4. **Kochmodus**: Steak → „Kochmodus starten“ → Timer bei Schritt 4.
5. **Import**: Beispieltext aus der Anleitung → „Text einfügen“;
   Chefkoch-Link → „Webseite“; Foto/PDF in den Simulator ziehen.
6. **Eigene Kategorie**: iPad-Sidebar „Kategorien“ (iPhone: Dashboard) →
   „+“ → Name, Symbol, Unterkategorien.
7. **Backup**: Einstellungen → „Backup erstellen“ → in Dateien/Drive
   sichern; danach „Backup wiederherstellen“ → Datei wählen → Hinzufügen
   oder Ersetzen. (Roundtrip verifiziert: 6 → 12 Rezepte, Fachdaten bleiben.)

## Ideen für Version 2

- Reife-Tracker für Wurst & Schinken (Wiegen, Verlaufskurve, Erinnerungen)
- Web-Parser für Seiten ohne strukturierte Daten (Readability-Heuristik)
- Spotlight-Integration; weitere Widgets („Zuletzt gekocht“, Zufallsrezept)
- Siri/Kurzbefehle im Kochmodus („nächster Schritt“, freihändig)
- Timer als Live-Aktivität im Sperrbildschirm/Dynamic Island
