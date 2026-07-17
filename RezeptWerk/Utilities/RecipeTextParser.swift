import Foundation

/// Das „Gehirn“ aller Text-Importe: zerlegt einen rohen Rezepttext
/// (aus OCR, PDF, Zwischenablage oder Web-Fallback) in Titel, Zutaten,
/// Schritte, Portionen und Zeiten.
///
/// Arbeitsweise in drei Stufen:
/// 1. **Abschnitte erkennen**: Überschriften wie „Zutaten“ oder
///    „Zubereitung“ teilen den Text in Bereiche.
/// 2. **Zeilen zuordnen**: Zeilen im Zutaten-Bereich werden als Zutaten
///    geparst, Zeilen im Zubereitungs-Bereich als Schritte.
/// 3. **Heuristik ohne Überschriften**: Fehlen die Überschriften (häufig
///    bei OCR), entscheidet das Zeilenmuster: „250 g Mehl“ sieht aus wie
///    eine Zutat, lange Sätze wie ein Schritt.
///
/// Der Parser muss nicht perfekt sein — der Nutzer prüft und korrigiert
/// das Ergebnis immer in der Import-Vorschau. Die Regeln sind bewusst
/// einfach gehalten und lassen sich hier zentral erweitern.
enum RecipeTextParser {

    // MARK: Erkennungslisten (hier zentral erweiterbar)

    /// Überschriften, die den Zutaten-Abschnitt einleiten.
    private static let ingredientHeaders = [
        "zutaten", "ingredients", "einkaufsliste", "du brauchst", "man braucht",
    ]

    /// Überschriften, die den Zubereitungs-Abschnitt einleiten.
    private static let stepHeaders = [
        "zubereitung", "zubereitungsschritte", "anleitung", "schritte",
        "so geht's", "so gehts", "instructions", "directions", "zubereiten",
        "arbeitsschritte",
    ]

    /// Überschriften für Notizen/Tipps.
    private static let noteHeaders = [
        "notizen", "tipp", "tipps", "hinweis", "hinweise", "notes",
    ]

    /// Bekannte Einheiten — nur diese werden als Einheit akzeptiert,
    /// alles andere gehört zum Zutatennamen.
    private static let knownUnits: Set<String> = [
        "g", "gr", "kg", "mg", "ml", "cl", "l", "el", "tl", "msp",
        "prise", "prisen", "stück", "st", "stk", "pck", "päckchen", "packung",
        "bund", "zehe", "zehen", "knolle", "dose", "dosen", "glas", "gläser",
        "becher", "tasse", "tassen", "scheibe", "scheiben", "blatt", "blätter",
        "zweig", "zweige", "stange", "stangen", "tropfen", "schuss", "würfel",
        "handvoll", "kugel", "kugeln", "riegel", "tüte", "tüten", "beutel",
    ]

    // MARK: Haupteinstieg

    static func parse(_ text: String) -> ParsedRecipe {
        var result = ParsedRecipe()
        result.rawText = text

        // Zeilen vorbereiten: trimmen, Leerzeilen merken wir uns als Absatztrenner.
        let rawLines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }

        // Aktueller Abschnitt während des Durchlaufs.
        enum Section { case start, ingredients, steps, notes }
        var section = Section.start

        var pendingStepLines: [String] = []
        var introLines: [String] = []

        /// Absätze im Schritt-Bereich abschließen: gesammelte Zeilen → ein Schritt.
        func flushStep() {
            let joined = pendingStepLines.joined(separator: " ")
                .trimmingCharacters(in: .whitespaces)
            if !joined.isEmpty {
                result.steps.append(stripStepNumber(joined))
            }
            pendingStepLines = []
        }

        for line in rawLines {
            // Leerzeile: im Schritt-Bereich bedeutet das „Absatz fertig“.
            if line.isEmpty {
                if section == .steps { flushStep() }
                continue
            }

            // 1. Ist die Zeile eine Abschnitts-Überschrift?
            if let newSection = detectHeader(line) {
                if section == .steps { flushStep() }
                switch newSection {
                case "ingredients": section = .ingredients
                case "steps": section = .steps
                case "notes": section = .notes
                default: break
                }
                continue
            }

            // 2. Metadaten-Zeilen (Portionen, Zeiten, Tags) überall erkennen.
            if let servings = parseServings(line) {
                result.servings = servings
                continue
            }
            if let (kind, minutes) = parseTimeLine(line) {
                if kind == "prep" { result.prepMinutes = minutes } else { result.cookMinutes = minutes }
                continue
            }
            if let tags = parseTagsLine(line) {
                result.tags.append(contentsOf: tags)
                continue
            }

            // 3. Zeile dem aktuellen Abschnitt zuordnen.
            switch section {
            case .start:
                if result.title.isEmpty {
                    // Die erste „normale“ Zeile ist der Titel.
                    result.title = line
                } else {
                    // Weitere Zeilen vor dem ersten Abschnitt: oft eine
                    // kurze Beschreibung — oder (ohne Überschriften) schon
                    // Zutaten/Schritte. Das entscheidet die Heuristik.
                    if looksLikeIngredient(line) {
                        section = .ingredients
                        result.ingredients.append(parseIngredientLine(line))
                    } else if isNumberedStep(line) || line.count > 80 {
                        section = .steps
                        pendingStepLines.append(line)
                    } else {
                        introLines.append(line)
                    }
                }

            case .ingredients:
                // Eine lange Satz-Zeile mitten im Zutatenblock? Dann hat
                // vermutlich die Zubereitung ohne Überschrift begonnen.
                if !looksLikeIngredient(line), line.count > 80 || isNumberedStep(line) {
                    section = .steps
                    pendingStepLines.append(line)
                } else {
                    result.ingredients.append(parseIngredientLine(line))
                }

            case .steps:
                if isNumberedStep(line) {
                    // Neue Nummer = neuer Schritt.
                    flushStep()
                    pendingStepLines.append(line)
                } else {
                    pendingStepLines.append(line)
                }

            case .notes:
                result.notes += (result.notes.isEmpty ? "" : "\n") + line
            }
        }
        flushStep()

        // Einleitungszeilen als Notiz übernehmen (gekürzt), damit nichts verloren geht.
        if !introLines.isEmpty {
            let intro = introLines.joined(separator: " ").prefix(300)
            result.notes = result.notes.isEmpty ? String(intro) : "\(intro)\n\(result.notes)"
        }

        if result.title.isEmpty {
            result.title = "Importiertes Rezept"
        }

        return result
    }

    // MARK: Überschriften

    /// Erkennt Abschnitts-Überschriften wie „Zutaten:“ oder „ZUBEREITUNG“.
    private static func detectHeader(_ line: String) -> String? {
        // Überschriften sind kurz — lange Sätze scheiden sofort aus.
        guard line.count < 40 else { return nil }
        let cleaned = line
            .lowercased()
            .trimmingCharacters(in: CharacterSet(charactersIn: ":–-– "))

        if ingredientHeaders.contains(where: { cleaned == $0 || cleaned.hasPrefix($0 + " ") }) {
            return "ingredients"
        }
        if stepHeaders.contains(where: { cleaned == $0 || cleaned.hasPrefix($0 + " ") }) {
            return "steps"
        }
        if noteHeaders.contains(where: { cleaned == $0 }) {
            return "notes"
        }
        return nil
    }

    // MARK: Zutaten

    /// Sieht die Zeile wie eine Zutat aus? (beginnt mit Menge oder Aufzählungszeichen)
    private static func looksLikeIngredient(_ line: String) -> Bool {
        let stripped = stripBullet(line)
        guard let first = stripped.first else { return false }
        if first.isNumber { return stripped.count < 70 }
        if "½¼¾⅓⅔⅛".contains(first) { return true }
        // Aufzählungszeichen am Anfang der Originalzeile.
        if let firstOriginal = line.first, "-–•*".contains(firstOriginal) { return stripped.count < 70 }
        return false
    }

    /// Zerlegt eine Zutatenzeile in Menge, Einheit und Name.
    /// Beispiele: „250 g Mehl“, „1,5 kg Rinderbrust“, „2 Eier“, „Salz“.
    static func parseIngredientLine(_ line: String) -> ParsedIngredient {
        var rest = stripBullet(line)

        // Menge am Zeilenanfang lesen (inkl. „1 1/2“, „½“, „1,5“, „2-3“).
        let (amount, afterAmount) = parseLeadingAmount(rest)
        rest = afterAmount

        // Ist das nächste Wort eine bekannte Einheit?
        var unit = ""
        let words = rest.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
        if amount != nil, let firstWord = words.first {
            let candidate = firstWord
                .trimmingCharacters(in: CharacterSet(charactersIn: "."))
                .lowercased()
            if knownUnits.contains(candidate) {
                unit = normalizeUnit(candidate)
                rest = words.count > 1 ? String(words[1]) : ""
            }
        }

        return ParsedIngredient(
            amount: amount,
            unit: unit,
            name: rest.trimmingCharacters(in: .whitespaces)
        )
    }

    /// Entfernt Aufzählungszeichen am Zeilenanfang („- “, „• “, „* “).
    private static func stripBullet(_ line: String) -> String {
        var result = line
        while let first = result.first, "-–•*◦▪︎ ".contains(first) {
            result.removeFirst()
        }
        return result.trimmingCharacters(in: .whitespaces)
    }

    /// Liest eine Menge am Textanfang und gibt (Menge, Resttext) zurück.
    private static func parseLeadingAmount(_ text: String) -> (Double?, String) {
        var working = text

        // Unicode-Brüche zuerst: „½ TL Salz“.
        let fractions: [Character: Double] = ["½": 0.5, "¼": 0.25, "¾": 0.75, "⅓": 0.333, "⅔": 0.667, "⅛": 0.125]
        if let first = working.first, let fraction = fractions[first] {
            working.removeFirst()
            return (fraction, working.trimmingCharacters(in: .whitespaces))
        }

        // Zahl am Anfang: „250“, „1,5“, „1.5“, „1 1/2“, „2-3“ (→ erster Wert).
        let pattern = #"^(\d+(?:[.,]\d+)?)(?:\s+(\d+)/(\d+))?"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: working, range: NSRange(working.startIndex..., in: working)),
              let fullRange = Range(match.range, in: working),
              let numberRange = Range(match.range(at: 1), in: working)
        else {
            return (nil, text)
        }

        var amount = Double(working[numberRange].replacingOccurrences(of: ",", with: ".")) ?? 0

        // Gemischter Bruch „1 1/2“?
        if let zRange = Range(match.range(at: 2), in: working),
           let nRange = Range(match.range(at: 3), in: working),
           let zaehler = Double(working[zRange]), let nenner = Double(working[nRange]), nenner > 0 {
            amount += zaehler / nenner
        }

        working.removeSubrange(fullRange)
        // Reiner Bruch ohne führende Ganzzahl: „1/2 Zwiebel“ → 1 / 2.
        if amount > 0, working.first == "/" {
            working.removeFirst()
            let parts = working.split(separator: " ", maxSplits: 1)
            if let nenner = Double(parts.first.map(String.init) ?? ""), nenner > 0 {
                amount = amount / nenner
                working = parts.count > 1 ? String(parts[1]) : ""
            }
        }

        return (amount > 0 ? amount : nil, working.trimmingCharacters(in: .whitespaces))
    }

    /// Vereinheitlicht Einheiten-Schreibweisen („EL“ statt „el“).
    private static func normalizeUnit(_ unit: String) -> String {
        switch unit {
        case "el": return "EL"
        case "tl": return "TL"
        case "msp": return "Msp."
        case "gr": return "g"
        case "st", "stk": return "Stück"
        case "pck": return "Pck."
        default: return unit
        }
    }

    // MARK: Schritte

    /// Beginnt die Zeile mit einer Schritt-Nummer („1.“, „2)“, „Schritt 3:“)?
    private static func isNumberedStep(_ line: String) -> Bool {
        line.range(of: #"^(schritt\s+)?\d{1,2}[.):]"#, options: [.regularExpression, .caseInsensitive]) != nil
    }

    /// Entfernt Schritt-Nummern am Anfang („1. “, „Schritt 2: “).
    private static func stripStepNumber(_ text: String) -> String {
        text.replacingOccurrences(
            of: #"^(schritt\s+)?\d{1,2}[.):]\s*"#,
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
    }

    // MARK: Metadaten

    /// Erkennt Portionsangaben: „für 4 Personen“, „4 Portionen“, „Portionen: 4“.
    private static func parseServings(_ line: String) -> Int? {
        guard line.count < 50 else { return nil }
        let lowered = line.lowercased()
        guard lowered.contains("person") || lowered.contains("portion") || lowered.contains("serving") else {
            return nil
        }
        if let range = lowered.range(of: #"\d{1,2}"#, options: .regularExpression) {
            return Int(lowered[range])
        }
        return nil
    }

    /// Erkennt Zeit-Zeilen: „Zubereitungszeit: 20 Min.“, „Garzeit 1 Std. 30 Min.“
    /// Rückgabe: ("prep"|"cook", Minuten).
    private static func parseTimeLine(_ line: String) -> (String, Int)? {
        guard line.count < 60 else { return nil }
        let lowered = line.lowercased()

        let isPrep = lowered.contains("zubereitungszeit") || lowered.contains("arbeitszeit")
            || lowered.contains("vorbereitungszeit") || lowered.contains("prep time")
        let isCook = lowered.contains("garzeit") || lowered.contains("kochzeit")
            || lowered.contains("backzeit") || lowered.contains("grillzeit")
            || lowered.contains("cook time") || lowered.contains("bratzeit")
            || lowered.contains("gesamtzeit")

        guard isPrep || isCook else { return nil }
        guard let minutes = parseDuration(lowered), minutes > 0 else { return nil }
        return (isPrep ? "prep" : "cook", minutes)
    }

    /// Liest „1 Std. 20 Min.“, „90 Minuten“, „2 h“ … und liefert Minuten.
    static func parseDuration(_ text: String) -> Int? {
        let lowered = text.lowercased()
        var minutes = 0

        if let match = lowered.range(of: #"(\d+)\s*(stunden|stunde|std|h)\b"#, options: .regularExpression) {
            let digits = lowered[match].prefix(while: \.isNumber)
            minutes += (Int(digits) ?? 0) * 60
        }
        if let match = lowered.range(of: #"(\d+)\s*(minuten|minute|min|m)\b"#, options: .regularExpression) {
            let digits = lowered[match].prefix(while: \.isNumber)
            minutes += Int(digits) ?? 0
        }
        return minutes > 0 ? minutes : nil
    }

    /// Erkennt explizite Tag-Zeilen: „Tags: schnell, Grill, Sonntag“.
    private static func parseTagsLine(_ line: String) -> [String]? {
        let lowered = line.lowercased()
        guard lowered.hasPrefix("tags:") || lowered.hasPrefix("schlagworte:") else { return nil }
        guard let colonIndex = line.firstIndex(of: ":") else { return nil }
        let tags = line[line.index(after: colonIndex)...]
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && $0.count <= 30 }
        return tags.isEmpty ? nil : tags
    }
}
