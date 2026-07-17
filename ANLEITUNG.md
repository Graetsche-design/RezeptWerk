# RezeptWerk – Anleitung (ganz einfach erklärt)

Diese Anleitung führt dich Schritt für Schritt durch alles: App öffnen,
starten, ausprobieren — und was du tust, wenn etwas hakt. Du musst nichts
programmieren. Alles ist schon fertig.

---

## 1. Was du brauchst

- Einen **Mac** mit **Xcode 16 oder neuer** (du hast Xcode 26.5 — perfekt).
  Xcode gibt es kostenlos im Mac App Store.
- Sonst nichts. Keine Pakete, keine Anmeldung, kein Internet nötig.

---

## 2. Projekt öffnen

1. Öffne den Ordner `Rezepteapp` im Finder.
2. Mache einen **Doppelklick auf `RezeptWerk.xcodeproj`** (das blaue Symbol).
3. Xcode öffnet sich und zeigt links alle Dateien des Projekts.
4. Warte beim allerersten Öffnen einen Moment — Xcode „indiziert“ das
   Projekt (unten läuft kurz ein Fortschrittsbalken).

---

## 3. App starten (im Simulator)

Der Simulator ist ein virtuelles iPhone auf deinem Mac.

1. Schau ganz oben in der Mitte des Xcode-Fensters. Dort steht
   **RezeptWerk** und daneben ein Gerätename.
2. Klicke auf den Gerätenamen und wähle z. B. **iPhone 17 Pro**
   (oder ein iPad, wenn du das iPad-Layout sehen willst).
3. Drücke den **▶-Knopf** oben links (oder `Cmd + R`).
4. Beim ersten Mal dauert es 1–2 Minuten. Dann öffnet sich der Simulator
   und RezeptWerk startet — mit sechs Beispielrezepten.

> **Tipp:** Hell-/Dunkelmodus des Simulators umschalten:
> Im Simulator-Menü `Features → Toggle Appearance` (oder `Shift + Cmd + A`).

---

## 4. App auf dein echtes iPhone bringen (optional)

1. Schließe dein iPhone mit dem Kabel an den Mac an.
2. Klicke in Xcode links oben auf das **blaue Projektsymbol „RezeptWerk“**,
   dann auf das Target **RezeptWerk → Signing & Capabilities**.
3. Bei **Team**: wähle dein persönliches Team aus (einfach mit deiner
   Apple-ID anmelden — das ist kostenlos).
4. Wähle oben dein iPhone als Gerät aus und drücke **▶**.
5. Beim ersten Mal meldet das iPhone „Nicht vertrauenswürdiger Entwickler“:
   Gehe am iPhone zu `Einstellungen → Allgemein → VPN & Geräteverwaltung`
   und vertraue deinem Account. Eventuell musst du außerdem den
   **Entwicklermodus** aktivieren (`Einstellungen → Datenschutz & Sicherheit
   → Entwicklermodus`) und das iPhone neu starten.

---

## 5. Die App ausprobieren — eine kleine Tour

### Ein Rezept ansehen
- Tippe auf dem **Start**-Tab auf „Rib-Eye-Steak vom Grill“.
- Probiere den **Portionsrechner**: Bei „Zutaten“ die Portionen hochstellen —
  alle Mengen rechnen automatisch um.
- Schau dir den **Käsekrakauer** an (Tab „Rezepte“): Dort siehst du den
  besonderen Fachdaten-Block für Wurst & Räuchern mit NPS-Menge,
  Temperaturen und dem Hygiene-Hinweis.

### Ein eigenes Rezept anlegen
1. Start-Tab → großer Knopf **„Neues Rezept“**.
2. Titel eintippen (nur der ist Pflicht), nach Lust Zutaten und Schritte.
3. Oben rechts **Speichern**. Fertig — das Rezept ist im Tab „Rezepte“.

### Den Kochmodus testen
1. Öffne ein Rezept → **„Kochmodus starten“**.
2. Blättere mit **Weiter/Zurück** oder durch Wischen.
3. Beim Steak-Rezept haben Schritte einen **Timer** — drücke **Start**.
4. Über das Listen-Symbol oben rechts kannst du jederzeit die **Zutaten**
   einblenden und abhaken.
5. Der Bildschirm bleibt im Kochmodus automatisch an.
6. Die Schriftgröße stellst du unter `Einstellungen → Kochmodus` ein.

### Import testen: Text einfügen (der einfachste Test)
1. Kopiere diesen Beispieltext (markieren → kopieren):

   ```text
   Bratkartoffeln wie früher
   Für 2 Personen
   Zubereitungszeit: 10 Minuten
   Garzeit: 25 Minuten

   Zutaten
   800 g festkochende Kartoffeln
   2 EL Butterschmalz
   1 Zwiebel
   100 g Speckwürfel
   Salz

   Zubereitung
   1. Kartoffeln als Pellkartoffeln kochen, ausdampfen lassen und in Scheiben schneiden.
   2. Schmalz in einer Eisenpfanne erhitzen und die Kartoffeln goldbraun braten.
   3. Zwiebel und Speck zugeben und mitbraten, mit Salz abschmecken.
   ```

2. App: Tab **Importieren → „Text einfügen“** → Knopf **Einfügen** →
   **„Text erkennen“**.
3. Du siehst die **Import-Vorschau**: Titel, Portionen, Zeiten, Zutaten und
   Schritte wurden erkannt.
4. **„Prüfen, anpassen & speichern“** → kontrollieren → **Speichern**.

### Import testen: Webseite
1. Tab **Importieren → „Webseite“**.
2. Füge einen Rezept-Link ein, z. B. von chefkoch.de (im Simulator kannst
   du normal tippen oder über den Mac einfügen: `Cmd + V`).
3. **„Rezept laden“** — Titel, Zutaten, Schritte und meist auch das Bild
   werden übernommen.

### Import testen: Foto mit Texterkennung (OCR)
1. Ziehe am Mac ein Foto von einem Rezept (z. B. abfotografierte
   Kochbuchseite) einfach **per Maus in das Simulator-Fenster** —
   es landet in der Foto-Mediathek des Simulators.
2. Tab **Importieren → „Foto oder Scan“ → „Foto aus der Mediathek wählen“**.
3. Die App erkennt den Text und zeigt die Vorschau.
   (Der Kamera-Scanner erscheint nur auf echten Geräten — der Simulator
   hat keine Kamera.)

### Import testen: PDF
1. Ziehe eine Rezept-PDF in das Simulator-Fenster (sie landet in der
   Dateien-App) oder nutze eine PDF aus iCloud Drive.
2. Tab **Importieren → „PDF“ → „PDF auswählen“**.

### Backup sichern und wiederherstellen (z. B. Google Drive)
1. Tab **Einstellungen** → Abschnitt **„Backup (Google Drive, Dropbox …)“**.
2. **„Backup erstellen“** → es öffnet sich der „In Dateien sichern“-Dialog.
   Wähle dort **Google Drive** (oder iCloud Drive, „Auf meinem iPhone“ …).
3. Zum Zurückholen: **„Backup wiederherstellen“** → die Datei auswählen →
   **„Hinzufügen“** (ergänzt) oder **„Alles ersetzen“** (überschreibt).

> Das Backup ist **eine einzige Datei** mit allen Rezepten, Bildern,
> Kategorien, Koch-Notizen und Wurst-Fachdaten. Damit kannst du auch auf
> ein neues iPhone umziehen, ganz ohne iCloud.

### Neu in Version 1.5: Werkzeuge, Koch-Notizen und Widget

**Werkzeuge (Kerntemperaturen & Wurst-Rechner):**
1. Tab **Start** → Bereich **„Werkzeuge“** (unter der Einkaufsliste).
2. **Kerntemperaturen**: nachschlagen oder oben suchen (z. B. „Steak“).
   Die Werte kannst du in `Views/Tools/KerntemperaturData.swift` jederzeit
   selbst anpassen — die Ansicht übernimmt sie automatisch.
3. **Wurst-Rechner**: Unter **Fleisch** deine Sorten mit Gewicht eintragen
   (z. B. Schweineschulter 1,5 kg + Rinderbrust 1 kg — die App zeigt den
   Anteil in Prozent). Über **„Vorlage“** eine Voreinstellung laden — alle
   Mengen rechnen sich sofort auf das Gesamtgewicht hoch (2,5 kg ×
   18 g/kg NPS = 45 g). Zeilen lassen sich ändern, ergänzen und löschen;
   beide Listen merkt sich die App.
4. **Als Rezept speichern**: Der Knopf unter dem Ergebnis macht aus dem
   Rechner-Stand ein richtiges Rezept — mit dem Fleisch-Mix und den
   fertig berechneten Mengen als Zutatenliste plus Fachdaten (Fleischmenge,
   NPS und Gewürze je kg), einsortiert in „Wurst & Räuchern“. Nur noch
   Namen eingeben, fertig.

**Koch-Notizen (Kochjournal):**
1. In jedem Rezept gibt es den Abschnitt **„Meine Koch-Notizen“** →
   **„Hinzufügen“** — die Notiz bekommt automatisch das heutige Datum.
2. Oder direkt nach dem Kochen: Auf der Abschlussseite des Kochmodus
   („Guten Appetit!“) steht ein Notizfeld — eintippen, **Fertig**, erledigt.
3. Löschen: der kleine ⊖-Knopf neben der Notiz.

**Homescreen-Widget „Heute auf dem Wochenplan“:**
1. Wichtig: Erst die App einmal öffnen und im Wochenplan etwas für heute
   einplanen (das Widget bekommt seine Daten von der App).
2. Auf dem Homescreen eine freie Stelle **lange drücken** → oben links
   **+** → **RezeptWerk** suchen → Größe wählen → **Widget hinzufügen**.
3. Das Widget wechselt um Mitternacht von selbst auf den nächsten Tag.

> **Einmalig fürs echte iPhone** (im Simulator nicht nötig): In Xcode das
> Target **RezeptWerkWidget** anklicken → **Signing & Capabilities** →
> **+ Capability → App Groups** → **`group.de.rezeptwerk.app`** ankreuzen —
> genauso, wie du es bei der Teilen-Erweiterung gemacht hast.

### Neu in Version 2.0: Tauschen, Timer-Klingeln, Schritt-Fotos

**Rezepte tauschen:**
1. Rezept öffnen → Teilen-Knopf → **„Als RezeptWerk-Datei teilen“** →
   z. B. per WhatsApp, Mail oder als Forum-Anhang verschicken.
2. Der Empfänger (mit RezeptWerk) tippt die Datei an — das Rezept öffnet
   sich bei ihm als Vorschau im Editor: prüfen, anpassen, speichern.
3. Deine Bewertung, dein Favoriten-Herz und deine Koch-Notizen werden
   **nicht** mitgeschickt — geteilt wird nur das Rezept selbst.

**Timer klingelt jetzt überall:**
Beim allerersten Timer-Start fragt die App einmal um Erlaubnis für
Mitteilungen. Danach klingelt der Schritt-Timer auch, wenn du kurz in
eine andere App wechselst oder das iPhone sperrst. In der App selbst
bleibt alles wie gewohnt (Anzeige + Vibration).

**Foto je Schritt:**
Im Editor hat jeder Schritt jetzt einen Knopf **„Foto zum Schritt“**.
Das Bild erscheint in der Detailansicht und groß im Kochmodus —
praktisch für „so muss der Teig aussehen“.

### Git & Tests (für dich als Entwickler)

Seit Version 2.0 hat das Projekt eine **Versionsverwaltung (Git)**:
Jeder Arbeitsstand ist gesichert, nichts geht mehr verloren.
- In Xcode siehst du die Historie unter **Integrate → Show Commits**
  (bzw. im Navigator-Bereich „Source Control“).
- Eigene Sicherungspunkte: Menü **Integrate → Commit** — Haken bei den
  Dateien setzen, kurze Beschreibung eintippen, fertig.

Außerdem gibt es **automatische Tests** (Ziel `RezeptWerkTests`):
- In Xcode einfach **⌘U** drücken — alle Tests laufen im Simulator.
- Im Terminal ginge `xcodebuild test …`, das braucht aber einmalig
  `sudo xcode-select -s /Applications/Xcode.app` (Admin-Passwort) —
  in Xcode per ⌘U ist es ohne alles möglich.

### iCloud-Synchronisierung (optional)
iCloud ist anfangs **ausgeschaltet** — die App speichert lokal und läuft
sofort. Wenn du deine Rezepte automatisch über mehrere Apple-Geräte
synchron halten willst, brauchst du einen **kostenpflichtigen
Apple-Developer-Account** und diese drei Schritte:

1. In Xcode oben das blaue Projekt **RezeptWerk** anklicken → Target
   **RezeptWerk** → Reiter **Signing & Capabilities**.
2. **„+ Capability“** (oben links) → **iCloud** → bei **Services** ein
   Häkchen bei **CloudKit** setzen und den Container
   **`iCloud.de.rezeptwerk.app`** ankreuzen.
3. App starten → **Einstellungen → iCloud-Synchronisierung** einschalten →
   App einmal neu starten.

Wenn du diese Schritte (noch) nicht machst, passiert nichts Schlimmes: Der
Schalter zeigt dann einfach keine Wirkung, und alles bleibt lokal.

### Nachricht an alle Nutzer senden (z. B. Update-Hinweis)

Du kannst allen Nutzern eine Meldung anzeigen — etwa: *„Demnächst erscheint
ein Update, bitte vorher ein Backup erstellen.“* Die App schaut dafür bei
jedem Start kurz auf deinem Server nach, ob eine Meldung vorliegt, und zeigt
sie dann als deutliches Hinweisfenster in der Bildschirmmitte (abgedunkelter
Hintergrund, „Verstanden“-Knopf). Kein Push-Dienst, kein Drittanbieter —
nur eine kleine Textdatei auf deinem Webspace.

**Einmalige Einrichtung — ✅ bereits erledigt:** Die Datei liegt unter
`https://kochenmitreima.de/Server/rezeptwerk-ankuendigung.json`, und diese
Adresse ist in der App eingetragen (in
`RezeptWerk/Services/Announcement/AnnouncementService.swift` bei
`announcementURL`). Nur falls die Datei jemals umzieht: die neue Adresse
dort eintragen — sie muss mit **https://** beginnen — und die App neu
veröffentlichen.

**Eine Meldung veröffentlichen:**

1. Öffne die JSON-Datei auf deinem Server und trage Titel und Text ein
   (am einfachsten: die Datei im Projektordner `Server/` auf dem Mac
   ändern und wieder hochladen):

   ```json
   {
     "titel": "Update-Hinweis",
     "nachricht": "Demnächst erscheint Version 1.1. Bitte erstelle vorher unter Einstellungen → Backup ein Backup.",
     "bis": "01.08.2026"
   }
   ```

2. Fertig — beim nächsten App-Start sehen alle Nutzer das Hinweisfenster.
3. Das Datum bei `"bis"` bestimmt, wie hartnäckig die Meldung ist:
   - **Mit Datum**: Das Fenster erscheint bis **einschließlich** diesem Tag
     **einmal pro Tag** erneut, auch wenn es schon mit „Verstanden“
     bestätigt wurde — ideal vor einem Update. Nach dem Tag verschwindet
     die Meldung **von selbst**, du musst nichts weiter tun.
   - **Ohne Datum** (`"bis": ""`): Jeder Nutzer sieht die Meldung nur ein
     einziges Mal; sie kommt erst wieder, wenn du den Text änderst.
4. Meldung vorzeitig beenden: einfach `"nachricht": ""` (leer) setzen.
   Die Datei bleibt auf dem Server liegen.

> **Tipps:** Veröffentliche den Hinweis 1–2 Wochen, bevor du das Update
> einreichst — so erreichst du auch Nutzer, die die App nur gelegentlich
> öffnen. Achte im Text auf gerade Anführungszeichen (`"`), nicht die
> „schönen“ aus Word — sonst ist die Datei kein gültiges JSON und das
> Banner bleibt einfach weg (die App stört das nicht, sie startet normal).

### Update im App Store veröffentlichen (Schritt für Schritt)

**In Xcode (hochladen):**

1. Oben in der Geräteauswahl **„Any iOS Device (arm64)“** wählen
   (mit Simulator-Auswahl ist Archivieren ausgegraut).
2. Menü **Product → Archive** — Xcode baut die Verkaufsversion und
   öffnet danach das Archiv-Fenster.
3. Dort **„Distribute App“ → „App Store Connect“ → „Upload“**, alle
   weiteren Fragen mit der Vorauswahl bestätigen.
4. Warten, bis Apples E-Mail „completed processing“ kommt (15–60 Min).

**In App Store Connect (einreichen):**

5. `appstoreconnect.apple.com` → **Meine Apps** → **RezeptWerk** →
   mit **+** eine neue Version anlegen. Die Nummer muss exakt der
   `MARKETING_VERSION` in Xcode entsprechen.
6. **„Was ist neu in dieser Version“** ausfüllen (2–3 Sätze reichen).
7. Bei **Build** den hochgeladenen Build auswählen. Verschlüsselungs-
   Frage: RezeptWerk nutzt nur Standard-Verschlüsselung (HTTPS) —
   Standard-Option wählen.
8. **„Diese Version manuell veröffentlichen“** ankreuzen, wenn du den
   Erscheinungstag selbst bestimmen willst (empfohlen, siehe unten).
9. **„Zur Prüfung hinzufügen“** — Apple prüft meist 1–2 Tage.

**Zeitplan passend zur Ankündigung:** Erst die Update-Meldung (mit
`"bis"`-Datum) auf den Server laden, dann einreichen, nach der Freigabe
ein paar Tage warten und die Version manuell veröffentlichen — so hatten
alle Nutzer Zeit, die Backup-Erinnerung zu sehen.

> **Gut zu wissen:** Muss dieselbe Versionsnummer ein zweites Mal
> hochgeladen werden (z. B. nach einer Korrektur), vorher in Xcode die
> Build-Nummer (`CURRENT_PROJECT_VERSION`) um 1 erhöhen — sonst lehnt
> Apple den Upload als Duplikat ab.

---

## 6. Wenn Xcode einen Fehler zeigt — keine Panik

| Was du siehst | Was es bedeutet | Was du tust |
|---|---|---|
| Rote Meldung beim Bauen | Xcode kann etwas nicht übersetzen | Klicke auf die Meldung — Xcode springt zur Stelle. Meist hilft Schritt „Aufräumen“ (s. u.) |
| App startet, stürzt sofort ab | Meist eine geänderte Datenbankstruktur | Lösche die App im Simulator (Symbol lange drücken → Entfernen) und starte neu — die Datenbank wird frisch angelegt |
| „Build Failed“ ohne klare Ursache | Alter Zwischenstand stört | `Product → Clean Build Folder` (`Shift + Cmd + K`), dann wieder ▶ |
| Simulator reagiert nicht | Simulator hängt | Simulator-Menü `Device → Restart`, zur Not Xcode neu starten |
| Gelbe Warnungen | Nur Hinweise, keine Fehler | Kannst du ignorieren — die App läuft trotzdem |
| „… doesn't support the iCloud capability“ / Signierfehler | iCloud-Berechtigung ist da, aber die Capability ist in Xcode noch nicht aktiviert | Entweder die iCloud-Capability einrichten (Abschnitt 5, „iCloud-Synchronisierung“) — oder, falls du iCloud (noch) nicht brauchst, in den Build-Einstellungen unter „Signing & Capabilities“ die iCloud-Capability wieder entfernen |

**Die goldene Reihenfolge bei Problemen:**
1. `Shift + Cmd + K` (aufräumen) → ▶
2. App im Simulator löschen → ▶
3. Xcode beenden und neu öffnen → ▶

---

## 7. Wo finde ich was im Code? (Kurzüberblick)

| Ordner | Inhalt |
|---|---|
| `RezeptWerk/App` | Start der App, Tab-/Sidebar-Navigation, Widget-Schnappschuss |
| `RezeptWerk/Models` | Die Datenbank-Modelle (Rezept, Zutat, Koch-Notiz …) |
| `RezeptWerk/Views` | Alle Bildschirme, nach Bereichen sortiert |
| `RezeptWerk/Views/Tools` | Kerntemperatur-Spickzettel und Wurst-Rechner (inkl. Werte) |
| `RezeptWerk/Services` | Import-Technik: OCR, PDF, Web, Zwischenablage |
| `RezeptWerk/Theme` | Farben, Schriften, Abstände, Karten, Buttons |
| `RezeptWerk/Components` | Wiederverwendbare Bausteine (Karten, Sterne, Chips) |
| `RezeptWerk/SampleData` | Standard-Kategorien und Beispielrezepte |
| `RezeptWerkWidget/` | Das Homescreen-Widget (eigenes kleines Programm) |
| `RezeptWerkTests/` | Automatische Tests (in Xcode mit ⌘U starten) |

Willst du z. B. eine Farbe ändern? → `Theme/AppColors.swift` bzw. die
Farb-Sets in `Assets.xcassets`. Eine neue Standard-Kategorie? →
`SampleData/DefaultCategories.swift`. Alles ist im Code auf Deutsch
kommentiert.

Viel Spaß mit RezeptWerk! 🔥
