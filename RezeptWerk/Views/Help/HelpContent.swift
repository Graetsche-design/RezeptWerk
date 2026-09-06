import Foundation

/// Der komplette Inhalt der In-App-Anleitung.
///
/// Hier sind alle Hilfe-Themen gesammelt — an einer Stelle gepflegt, damit
/// neue Funktionen leicht ergänzt werden können.
enum HelpContent {

    static let topics: [HelpTopic] = [
        overview,
        findRecipes,
        createRecipe,
        importRecipes,
        cookingMode,
        weekPlanner,
        shoppingList,
        sausage,
        tools,
        categories,
        shareExport,
        iCloud,
        backup,
        settings,
        tips,
    ]

    // MARK: 1. Überblick

    private static let overview = HelpTopic(
        title: "Überblick & erste Schritte",
        icon: "sparkles",
        summary: "Wie die App aufgebaut ist und wo du was findest.",
        blocks: [
            .paragraph("RezeptWerk ist dein digitales Rezept-Werkzeug fürs Kochen, Grillen, Wursten und Räuchern. Alle Daten bleiben auf deinem Gerät – ganz ohne Konto."),
            .heading("Die Bereiche"),
            .bullets([
                "Start: dein Dashboard mit Suche, Favoriten, zuletzt hinzugefügten Rezepten, Wochenplan und Einkaufsliste.",
                "Rezepte: alle Rezepte mit Suche, Filter und Sortierung.",
                "Favoriten: deine mit dem Herz markierten Rezepte.",
                "Importieren: Rezepte aus Foto, PDF, Webseite oder Text übernehmen.",
                "Einstellungen: Erscheinungsbild, Kochmodus, iCloud, Backup und diese Anleitung.",
            ]),
            .paragraph("Auf dem iPad erscheinen zusätzlich Wochenplan, Einkaufsliste und Kategorien in der seitlichen Leiste. Auf dem iPhone erreichst du diese bequem über die Karten auf der Startseite."),
            .tip("Die App startet mit ein paar Beispielrezepten, damit alles lebendig aussieht. Du kannst sie behalten, bearbeiten oder in den Einstellungen jederzeit neu laden."),
        ]
    )

    // MARK: 2. Rezepte finden

    private static let findRecipes = HelpTopic(
        title: "Rezepte finden & durchsuchen",
        icon: "magnifyingglass",
        summary: "Suchen, filtern, sortieren und Favoriten markieren.",
        blocks: [
            .heading("Suchen"),
            .paragraph("Tippe oben in das Suchfeld. Gesucht wird in Titel, Zutaten, Tags und Notizen – du findest also auch ein Rezept, wenn du nur eine Zutat im Kopf hast."),
            .heading("Filtern & sortieren"),
            .steps([
                "Öffne den Tab „Rezepte“.",
                "Tippe oben rechts auf das Filter-Symbol.",
                "Wähle Kategorie, Unterkategorie, Schwierigkeit, Tags oder „Nur Favoriten“.",
                "Die Sortierung änderst du über das Symbol oben links (Neueste, Titel A–Z, beste Bewertung).",
            ]),
            .heading("Favoriten"),
            .paragraph("Tippe in einem Rezept auf das Herz – es erscheint dann im Tab „Favoriten“ und im Karussell auf der Startseite."),
            .tip("Tippe in der Rezeptliste lange auf eine Karte – ein Schnellmenü bietet Favorit, Bearbeiten und Löschen."),
        ]
    )

    // MARK: 3. Rezept anlegen

    private static let createRecipe = HelpTopic(
        title: "Rezept anlegen & bearbeiten",
        icon: "square.and.pencil",
        summary: "Die Eingabemaske Abschnitt für Abschnitt erklärt.",
        blocks: [
            .paragraph("Ein neues Rezept legst du über den Button „Neues Rezept“ auf der Startseite oder das „+“ in der Rezeptliste an. Zum Bearbeiten öffnest du ein Rezept und tippst auf „Bearbeiten“."),
            .heading("Die Abschnitte"),
            .bullets([
                "Grunddaten: Titel (Pflicht), Portionen, Schwierigkeit.",
                "Bild: bis zu drei Fotos – das erste ist das Titelbild.",
                "Kategorie & Unterkategorie.",
                "Zutaten: Menge, Einheit und Name getrennt. Über „Bearbeiten“ umsortieren oder löschen.",
                "Schritte: je Schritt ein Text und optional ein Timer (in Minuten).",
                "Zeiten: Vorbereitung, Gar-/Backzeit, Ruhezeit.",
                "Bewertung & Favorit.",
                "Geeignet für: bei welchen Mahlzeiten das Rezept im Wochenplan vorgeschlagen wird.",
                "Tags, Notizen und Quelle (Text und/oder Link).",
                "Wurst & Räuchern: Fachdaten (siehe eigenes Thema).",
            ]),
            .tip("Nur der Titel ist Pflicht – alles andere kannst du nach und nach ergänzen. Mengen mit Komma (z. B. „1,5“) sind erlaubt."),
        ]
    )

    // MARK: 4. Importieren

    private static let importRecipes = HelpTopic(
        title: "Rezepte importieren",
        icon: "square.and.arrow.down",
        summary: "Aus Foto, PDF, Webseite oder Text – mit Vorschau.",
        blocks: [
            .paragraph("Im Tab „Importieren“ findest du vier Wege. Egal welcher: Am Ende siehst du immer eine Vorschau und kannst alles prüfen und anpassen, bevor gespeichert wird."),
            .heading("Foto oder Scan"),
            .bullets([
                "Rezept mit der Kamera scannen (begradigt die Seite automatisch) oder ein Foto aus der Mediathek wählen.",
                "Der Text wird automatisch erkannt (OCR) und in Titel, Zutaten und Schritte aufgeteilt.",
            ]),
            .heading("PDF, Webseite, Text"),
            .bullets([
                "PDF: Rezept-PDF auswählen – auch gescannte PDFs werden gelesen.",
                "Webseite: Link einfügen – bei den meisten Rezeptseiten werden Titel, Zutaten, Schritte und Bild übernommen.",
                "Text einfügen: kopierten Rezepttext einsetzen und erkennen lassen.",
            ]),
            .tip("Klappt eine Webseite nicht? Kopiere den Rezepttext von der Seite und nutze „Text einfügen“ – das funktioniert immer. Fotografiere Vorlagen bei gutem Licht und möglichst gerade."),
        ]
    )

    // MARK: 5. Kochmodus

    private static let cookingMode = HelpTopic(
        title: "Kochmodus",
        icon: "flame",
        summary: "Schritt für Schritt kochen, mit Timer und Großschrift.",
        blocks: [
            .paragraph("Öffne ein Rezept und tippe auf „Kochmodus starten“. Der Kochmodus ist fürs Arbeiten am Herd oder Grill gemacht: ruhig, dunkel und gut lesbar."),
            .bullets([
                "Ein Schritt pro Seite in sehr großer Schrift.",
                "Weiter und Zurück über die Buttons oder durch Wischen.",
                "Das Listen-Symbol oben rechts zeigt die Zutaten zum Abhaken – mit den Mengen für die Portionen, die du vorher im Portionsrechner eingestellt hast (oder die im Wochenplan zum Gericht gehören).",
                "Hat ein Schritt einen Timer, erscheint er automatisch – mit Start/Pause und Signal am Ende.",
                "Der Bildschirm bleibt an, solange der Kochmodus offen ist.",
                "Am Ende kannst du das Rezept gleich bewerten.",
            ]),
            .tip("Die Schriftgröße im Kochmodus stellst du unter Einstellungen → Kochmodus ein (Normal, Groß, Sehr groß)."),
        ]
    )

    // MARK: 6. Wochenplan

    private static let weekPlanner = HelpTopic(
        title: "Wochenplan",
        icon: "calendar",
        summary: "Gerichte auf Tage und Mahlzeiten verteilen.",
        blocks: [
            .paragraph("Den Wochenplan öffnest du auf dem iPhone über die Karte „Wochenplan“ auf der Startseite, auf dem iPad über die Seitenleiste."),
            .steps([
                "Wähle einen Tag und tippe auf „Gericht planen“.",
                "Wähle die Mahlzeit (Frühstück, Mittag, Abend, Snack).",
                "Stelle die Portionen ein: „wie im Rezept“ oder eine feste Zahl – die wird gemerkt, weil sie meist deinem Haushalt entspricht.",
                "Tippe auf ein Rezept – fertig.",
                "Mit den Pfeilen ‹ › blätterst du durch die Wochen, „Heute“ springt zurück.",
                "Zum Entfernen tippst du beim geplanten Gericht auf das Minus-Symbol.",
            ]),
            .heading("Portionen"),
            .paragraph("Beim geplanten Gericht steht die Portionszahl in einer kleinen Kapsel – antippen ändert sie. Öffnest du das Gericht aus dem Plan, startet der Portionsrechner gleich mit dieser Zahl, und Kochmodus wie Einkaufsliste rechnen die Mengen entsprechend um."),
            .tip("Markiere bei deinen Rezepten unter „Geeignet für“, zu welchen Mahlzeiten sie passen. Beim Einplanen werden passende Rezepte dann oben mit „Geeignet“-Hinweis angezeigt."),
        ]
    )

    // MARK: 7. Einkaufsliste

    private static let shoppingList = HelpTopic(
        title: "Einkaufsliste",
        icon: "cart",
        summary: "Zutaten sammeln, zusammenfassen und abhaken.",
        blocks: [
            .paragraph("Die Einkaufsliste erreichst du über die Startseite, den iPad-Tab, den Wochenplan oder das Menü in einem Rezept."),
            .bullets([
                "„Aus Wochenplan übernehmen“ sammelt alle Zutaten der geplanten Woche – jedes Gericht mit seinen geplanten Portionen. Gleiche Zutaten werden zusammengefasst (z. B. 2× 200 g Mehl → 400 g Mehl).",
                "In einem Rezept fügst du über „Mehr → Zur Einkaufsliste“ dessen Zutaten hinzu – umgerechnet auf die Portionen, die du vorher im Portionsrechner eingestellt hast.",
                "Eigene Einträge tippst du unten ein, z. B. „2 Zwiebeln“.",
                "Tippen hakt einen Eintrag ab, Wischen löscht ihn.",
                "Das Teilen-Symbol oben rechts schickt die offenen Einträge als Text an WhatsApp, Nachrichten, Mail oder die Erinnerungen-App – praktisch, wenn jemand anderes einkauft.",
                "Über das Menü oben kannst du erledigte oder alle Einträge löschen.",
            ]),
        ]
    )

    // MARK: 8. Wurst & Räuchern

    private static let sausage = HelpTopic(
        title: "Wurst & Räuchern",
        icon: "smoke",
        summary: "Fachdaten für Wurst-, Pökel- und Räucherrezepte.",
        blocks: [
            .paragraph("Für Wurst- und Räucherrezepte gibt es zusätzliche Fachfelder. Sie erscheinen nur dort, wo sie sinnvoll sind – normale Rezepte bleiben schlank."),
            .heading("Fachdaten erfassen"),
            .paragraph("Im Editor den Schalter „Fachdaten erfassen“ einschalten (bei der Kategorie „Wurst & Räuchern“ geschieht das automatisch)."),
            .bullets([
                "Fleischmenge, Gewürze pro kg, Nitritpökelsalz (NPS) pro kg.",
                "Kutterhilfsmittel, Schüttung/Eiswasser, Darm/Kaliber.",
                "Räucherart (kalt/warm/heiß), Räucherzeit und -temperatur.",
                "Brühtemperatur, Kerntemperatur, Reifezeit, Trocknungszeit.",
                "Eigener Sicherheits- & Hygiene-Hinweis.",
            ]),
            .tip("Wiege Nitritpökelsalz grammgenau ab und halte die Kühlkette ein. Die Sicherheits- und Hygienehinweise werden in der Detailansicht hervorgehoben – nimm sie ernst."),
        ]
    )

    // MARK: 8b. Werkzeuge

    private static let tools = HelpTopic(
        title: "Werkzeuge",
        icon: "wrench.and.screwdriver",
        summary: "Kerntemperaturen, Wurst-Rechner, Pökel-Rechner, Umrechner.",
        blocks: [
            .paragraph("Auf der Startseite findest du unter „Werkzeuge“ vier Offline-Helfer für Küche, Grill und Räucherkammer."),
            .heading("Kerntemperaturen"),
            .paragraph("Eine durchsuchbare Nachschlagetabelle mit Gar-Temperaturen für Rind, Schwein, Geflügel, Lamm & Wild, Fisch sowie Wurst & Räuchern."),
            .heading("Wurst-Rechner"),
            .paragraph("Für die Wurstherstellung: Fleisch-Mix aus mehreren Sorten eingeben, Zutaten in Gramm je Kilogramm pflegen – alle Mengen werden live hochgerechnet. Mit Vorlagen für Brühwurst, Rohwurst und Rohschinken. Der Stand lässt sich als richtiges Rezept speichern."),
            .heading("Pökel-Rechner"),
            .paragraph("Fürs Nasspökeln: Fleischgewicht, Wassermenge und Lakenstärke eingeben – die App rechnet die NPS-Menge für die Lake aus und schätzt die Pökelzeit nach der dicksten Stelle des Fleischs, samt Hinweis zum Durchbrennen. Deine Eingaben werden gemerkt."),
            .heading("Umrechner"),
            .paragraph("Rechnet amerikanische Rezept-Angaben in deutsche Maße um: Cups, Esslöffel und Teelöffel zutatengenau in Gramm, Unzen und Pfund in Gramm, Grad Fahrenheit in Celsius – dazu die Gasherd-Stufen als Orientierung."),
            .tip("Alle Richtwerte in den Werkzeugen sind bewährte Anhaltspunkte – maßgeblich bleibt deine eigene, erprobte Rezeptur."),
        ]
    )

    // MARK: 9. Kategorien

    private static let categories = HelpTopic(
        title: "Kategorien",
        icon: "square.grid.2x2",
        summary: "Rezepte ordnen und eigene Kategorien anlegen.",
        blocks: [
            .paragraph("RezeptWerk bringt zwölf Kategorien mit – von Fleisch über Grillen bis Getränke – jeweils mit Unterkategorien."),
            .bullets([
                "Auf dem iPhone erreichst du die Kategorien über die Startseite, auf dem iPad über die Seitenleiste.",
                "Tippe eine Kategorie an, um ihre Rezepte zu sehen und nach Unterkategorie einzugrenzen.",
                "Mit dem „+“ legst du eigene Kategorien an; bei jeder Kategorie kannst du Unterkategorien ergänzen.",
            ]),
        ]
    )

    // MARK: 10. Teilen & Export

    private static let shareExport = HelpTopic(
        title: "Teilen & Export",
        icon: "square.and.arrow.up",
        summary: "Rezepte als PDF oder Text weitergeben.",
        blocks: [
            .paragraph("Öffne ein Rezept und tippe auf den Teilen-Knopf oben rechts."),
            .bullets([
                "Als PDF teilen: ein hochwertig gesetztes Kochbuch-Blatt mit Bild, Zutaten und Schritten.",
                "Als Text teilen: das Rezept als reiner Text – ideal für Nachrichten oder Mail.",
                "Über das System-Menü landet alles in Mail, Nachrichten, WhatsApp, „In Dateien sichern“ usw.",
            ]),
        ]
    )

    // MARK: 11. iCloud

    private static let iCloud = HelpTopic(
        title: "iCloud-Synchronisierung",
        icon: "icloud",
        summary: "Rezepte über alle deine Apple-Geräte synchron halten.",
        blocks: [
            .paragraph("Unter Einstellungen → iCloud-Synchronisierung schaltest du die Synchronisierung ein. Deine Rezepte sind dann automatisch auf allen Geräten mit derselben Apple-ID verfügbar."),
            .bullets([
                "Du musst auf dem Gerät bei iCloud angemeldet sein.",
                "Eine Änderung des Schalters wirkt nach einem Neustart der App.",
                "Die Statusanzeige zeigt, ob gerade synchronisiert wird oder wann zuletzt.",
            ]),
            .tip("Standardmäßig ist iCloud aus – die App speichert dann nur lokal. Das ist völlig in Ordnung, wenn du nur ein Gerät nutzt."),
        ]
    )

    // MARK: 12. Backup

    private static let backup = HelpTopic(
        title: "Backup & Wiederherstellen",
        icon: "externaldrive",
        summary: "Alle Rezepte als Datei sichern – z. B. in Google Drive.",
        blocks: [
            .paragraph("Unter Einstellungen → Backup sicherst du deinen kompletten Rezeptbestand als eine Datei."),
            .steps([
                "„Backup erstellen“ antippen.",
                "Im Dialog „In Dateien sichern“ einen Ort wählen – z. B. Google Drive, iCloud Drive oder Dropbox.",
                "Zum Zurückholen „Backup wiederherstellen“ → Datei wählen → „Hinzufügen“ (ergänzt) oder „Alles ersetzen“ (überschreibt).",
            ]),
            .paragraph("Das Backup enthält alle Rezepte mit Bildern, Kategorien, Tags und Wurst-Fachdaten – ideal auch für den Umzug auf ein neues Gerät."),
        ]
    )

    // MARK: 13. Einstellungen

    private static let settings = HelpTopic(
        title: "Einstellungen",
        icon: "gearshape",
        summary: "Erscheinungsbild, Kochmodus, Daten und mehr.",
        blocks: [
            .bullets([
                "Erscheinungsbild: Automatisch, Hell oder Dunkel.",
                "Kochmodus: Schriftgröße (Normal, Groß, Sehr groß) mit Live-Vorschau.",
                "iCloud-Synchronisierung und Backup (siehe eigene Themen).",
                "Deine Daten: Speicherort, Rezeptanzahl, Beispielrezepte neu laden.",
                "Import-Tipps und App-Info.",
            ]),
            .tip("„Beispielrezepte neu laden“ ersetzt nur die mitgelieferten Beispiele – deine eigenen Rezepte bleiben unangetastet."),
        ]
    )

    // MARK: 14. Tipps

    private static let tips = HelpTopic(
        title: "Tipps & Datenschutz",
        icon: "lightbulb",
        summary: "Kleine Helfer und wie mit deinen Daten umgegangen wird.",
        blocks: [
            .heading("Datenschutz"),
            .paragraph("RezeptWerk speichert alles ausschließlich auf deinem Gerät – und, falls du es einschaltest, in deiner privaten iCloud. Es gibt kein Konto, keine Werbung und keine Weitergabe an Dritte."),
            .heading("Praktische Tipps"),
            .bullets([
                "Prüfe nach jedem Import die Vorschau, bevor du speicherst.",
                "Nutze Tags wie „schnell“, „Sonntag“ oder „Dutch Oven“ – so findest du Rezepte später blitzschnell über den Filter.",
                "Der Portionsrechner in der Detailansicht rechnet alle Mengen automatisch um.",
                "Mache regelmäßig ein Backup, wenn du iCloud nicht nutzt.",
            ]),
        ]
    )
}
