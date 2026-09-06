Version 2.5 Coming soon

**Neue Funktionen**

- **Neues Design „Dunkle Glut“**: Die App ist jetzt durchgehend dunkel —
    Anthrazit wie Räucherholz, dunkle Karten, Creme-Text und glühendes
    Kupfer als Akzent. Jede Kategorie hat ihren eigenen Farbton, das
    Dashboard zeigt zwei große Schnellzugriffe und die Werkzeuge als
    kompakte Kacheln. Blendfrei in der Küche, ohne Umschalten.
- **Portionen im Wochenplan**: Beim Einplanen die Portionszahl einstellen
    („wie im Rezept“ oder eine feste Zahl, die gemerkt wird); am geplanten
    Gericht steht sie in einer Kapsel und lässt sich antippen und ändern.
    Wer ein Gericht aus dem Plan öffnet, bekommt den Portionsrechner gleich
    passend eingestellt.
- **Portionen wirken jetzt überall**: Kochmodus (Zutaten-Blatt) und „Zur
    Einkaufsliste“ rechnen mit den Portionen aus dem Portionsrechner; „Aus
    Wochenplan übernehmen“ rechnet jedes Gericht auf seine geplanten
    Portionen um.
- **Einkaufsliste teilen**: Das Teilen-Symbol schickt die offenen Einträge
    als Text an WhatsApp, Nachrichten, Mail oder die Erinnerungen-App.
- **Rezept duplizieren**: „Mehr → Duplizieren“ öffnet den Editor mit einer
    Kopie samt Bildern, Tags und Fachdaten — für Varianten wie
    „Chili-Krakauer“ aus „Käsekrakauer“. Bewertung und Favorit beginnen bei
    null, das Original bleibt unberührt.
- **Mehrere Timer gleichzeitig** im Kochmodus: Ein gestarteter Timer läuft
    weiter, wenn du weiterblätterst — Nudeln, Soße und Ofen parallel. Timer
    anderer Schritte erscheinen als Leiste oben (antippen springt zum
    Schritt), jeder klingelt für sich, auch bei gesperrtem Gerät.
- **Freihändig kochen**: Das Lautsprecher-Symbol im Kochmodus liest den
    Schritt vor, auf Wunsch automatisch bei jedem Schrittwechsel. Und Siri
    steuert den offenen Kochmodus: „Nächster Schritt in RezeptWerk“,
    „Vorheriger Schritt …“, „Schritt vorlesen …“, „Timer starten …“.
- **Spotlight**: Rezepte über die iOS-Suche finden — Titel, Kategorie, Tags
    und Zutaten, mit Titelbild; ein Tipp öffnet das Rezept direkt.
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
- **Hilfe aktualisiert**: Die In-App-Anleitung erklärt alle neuen
    Möglichkeiten — vom Wochenplan mit Portionen bis Siri und Spotlight —
    und alle vier Werkzeuge (auch Kerntemperaturen und Wurst-Rechner).
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
- **Werkzeuge** (neuer Bereich auf dem Start-Tab):
- **Kerntemperatur-Spickzettel** — Offline-Nachschlagetabelle mit Suche:
    Rind, Schwein, Geflügel, Lamm & Wild, Fisch, Wurst & Räuchern, inkl.
    Sicherheitshinweisen.
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
    selbstständig auf den nächsten Tag.
- **„Bildschirm immer an“** (Einstellungen → Bildschirm): Der Bildschirm
    wird nicht mehr automatisch dunkel, solange RezeptWerk geöffnet ist —
    praktisch in der Küche. Der Kochmodus hält den Bildschirm weiterhin
    immer wach, unabhängig vom Schalter.

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
- **Backup-Wiederherstellung abgesichert**: Bei zwei gleichnamigen
    Kategorien (konnte durch iCloud-Duplikate vorkommen) stürzte die
    Wiederherstellung ab — jetzt nicht mehr.
- **Kochmodus-Timer rechnet mit echter Uhrzeit**: Nach einem kurzen
    Wechsel in eine andere App zeigt der Timer sofort wieder die korrekte
    Restzeit (vorher „fror“ er ein und lief entsprechend zu spät ab).
- **Größere Tippflächen** im Kochmodus-Kopf (44 × 44 Punkte,
    Apple-Empfehlung) — besser bedienbar mit nassen Händen.
