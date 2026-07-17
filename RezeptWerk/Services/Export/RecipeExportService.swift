import Foundation
import UIKit
import WebKit

/// Erzeugt teilbare Fassungen eines Rezepts:
/// - **Klartext** für Messages, WhatsApp, Mail … (`plainText`)
/// - **PDF** im RezeptWerk-Kochbuch-Stil (`pdfData` / `writePDF`)
///
/// Das PDF entsteht in zwei Schritten:
/// 1. Das Rezept wird als HTML aufgebaut (mit CSS im Kochbuch-Look).
/// 2. Eine unsichtbare `WKWebView` rendert dieses HTML (volles WebKit →
///    Bilder und CSS zuverlässig), und `UIPrintPageRenderer` zerlegt das
///    Ergebnis automatisch in A4-Seiten.
///
/// Läuft auf dem MainActor, weil die PDF-Erzeugung (WebKit/UIKit) dort
/// gehört. `pdfData` ist `async`, weil die WebView das HTML erst laden muss.
@MainActor
enum RecipeExportService {

    // MARK: Klartext

    /// Sauber formatierter Rezepttext zum schnellen Teilen.
    static func plainText(for recipe: Recipe) -> String {
        var lines: [String] = [recipe.title]

        let subtitle = [recipe.category?.name, recipe.subcategory?.name]
            .compactMap { $0 }
            .joined(separator: " · ")
        if !subtitle.isEmpty {
            lines.append(subtitle)
        }

        var meta: [String] = []
        if recipe.rating > 0 { meta.append(stars(recipe.rating)) }
        meta.append("\(recipe.servings) Portionen")
        if recipe.totalMinutes > 0 { meta.append(FormatHelpers.minutesText(recipe.totalMinutes)) }
        meta.append(recipe.difficulty.label)
        lines.append(meta.joined(separator: " · "))

        if !recipe.sortedIngredients.isEmpty {
            lines.append("")
            lines.append("ZUTATEN")
            for ingredient in recipe.sortedIngredients {
                lines.append("• " + ingredient.displayText())
            }
        }

        if !recipe.sortedSteps.isEmpty {
            lines.append("")
            lines.append("ZUBEREITUNG")
            for (index, step) in recipe.sortedSteps.enumerated() {
                lines.append("\(index + 1). \(step.text)")
            }
        }

        if let details = recipe.sausageDetails, details.hasAnyValue {
            lines.append("")
            lines.append("WURST & RÄUCHERN")
            for (label, value) in sausageRows(details) {
                lines.append("\(label): \(value)")
            }
            if !details.safetyNotes.isEmpty {
                lines.append("Sicherheit & Hygiene: \(details.safetyNotes)")
            }
        }

        if !recipe.notes.isEmpty {
            lines.append("")
            lines.append("NOTIZEN")
            lines.append(recipe.notes)
        }

        if !recipe.sourceText.isEmpty || recipe.sourceURL != nil {
            lines.append("")
            var source = "Quelle: "
            if !recipe.sourceText.isEmpty { source += recipe.sourceText }
            if let url = recipe.sourceURL {
                source += (recipe.sourceText.isEmpty ? "" : " · ") + url.absoluteString
            }
            lines.append(source)
        }

        lines.append("")
        lines.append("— geteilt aus RezeptWerk")
        return lines.joined(separator: "\n")
    }

    // MARK: PDF

    /// A4 in Punkten (72 dpi).
    private static let pageSize = CGSize(width: 595.2, height: 841.8)

    /// Rendert das Rezept als mehrseitiges PDF (A4).
    static func pdfData(for recipe: Recipe) async -> Data {
        let webView = WKWebView(frame: CGRect(origin: .zero, size: pageSize))
        let loadWatcher = PDFLoadWatcher()
        webView.navigationDelegate = loadWatcher

        webView.loadHTMLString(html(for: recipe), baseURL: nil)
        await loadWatcher.waitUntilLoaded()
        // Kurze Atempause, damit Layout und Bilder sicher fertig sind.
        try? await Task.sleep(for: .milliseconds(80))

        return renderPDF(formatter: webView.viewPrintFormatter())
    }

    /// Zerlegt den fertig gerenderten Inhalt in A4-Seiten.
    private static func renderPDF(formatter: UIViewPrintFormatter) -> Data {
        let renderer = UIPrintPageRenderer()
        renderer.addPrintFormatter(formatter, startingAtPageAt: 0)

        let margin: CGFloat = 40
        let paperRect = CGRect(origin: .zero, size: pageSize)
        let printableRect = paperRect.insetBy(dx: margin, dy: margin)

        // `paperRect`/`printableRect` sind nur lesbar — per KVC gesetzt ist
        // der etablierte Standardweg für PDF-Erzeugung ohne Drucker.
        renderer.setValue(NSValue(cgRect: paperRect), forKey: "paperRect")
        renderer.setValue(NSValue(cgRect: printableRect), forKey: "printableRect")

        let data = NSMutableData()
        UIGraphicsBeginPDFContextToData(data, paperRect, nil)
        let pageCount = max(1, renderer.numberOfPages)
        renderer.prepare(forDrawingPages: NSRange(location: 0, length: pageCount))
        let bounds = UIGraphicsGetPDFContextBounds()
        for pageIndex in 0..<pageCount {
            UIGraphicsBeginPDFPage()
            renderer.drawPage(at: pageIndex, in: bounds)
        }
        UIGraphicsEndPDFContext()
        return data as Data
    }

    /// Schreibt das PDF in eine temporäre Datei mit lesbarem Namen
    /// (z. B. „Rib-Eye-Steak vom Grill.pdf“) — für `ShareLink`.
    static func writePDF(_ data: Data, title: String) -> URL? {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(sanitizedFileName(title)).pdf")
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    // MARK: HTML-Aufbau

    private static func html(for recipe: Recipe) -> String {
        var body = ""

        let eyebrow = [recipe.category?.name, recipe.subcategory?.name]
            .compactMap { $0 }
            .joined(separator: " · ")
        if !eyebrow.isEmpty {
            body += "<div class='eyebrow'>\(escape(eyebrow))</div>"
        }

        body += "<h1>\(escape(recipe.title))</h1>"

        var meta: [String] = []
        if recipe.rating > 0 { meta.append("<span class='stars'>\(stars(recipe.rating))</span>") }
        meta.append("\(recipe.servings) Portionen")
        if recipe.totalMinutes > 0 { meta.append(escape(FormatHelpers.minutesText(recipe.totalMinutes))) }
        meta.append(escape(recipe.difficulty.label))
        body += "<div class='meta'>\(meta.joined(separator: " &nbsp;•&nbsp; "))</div>"

        // Titelbild (als Base64 eingebettet, damit das PDF eigenständig ist).
        if let imageData = recipe.coverImageData, !imageData.isEmpty {
            body += "<img class='cover' src='data:image/jpeg;base64,\(imageData.base64EncodedString())'/>"
        }

        if !recipe.tagNames.isEmpty {
            let tags = recipe.tagNames.map { "<span class='tag'>\(escape($0))</span>" }.joined()
            body += "<div class='tags'>\(tags)</div>"
        }

        if !recipe.sortedIngredients.isEmpty {
            body += "<h2>Zutaten</h2><table class='ingredients'>"
            for ingredient in recipe.sortedIngredients {
                body += "<tr><td class='amount'>\(escape(amountText(ingredient)))</td>"
                body += "<td>\(escape(ingredient.name))</td></tr>"
            }
            body += "</table>"
        }

        if !recipe.sortedSteps.isEmpty {
            body += "<h2>Zubereitung</h2><ol class='steps'>"
            for step in recipe.sortedSteps {
                var text = escape(step.text)
                if let seconds = step.timerSeconds, seconds > 0 {
                    text += " <span class='timer'>&#9201; \(escape(FormatHelpers.timerText(seconds: seconds)))</span>"
                }
                body += "<li>\(text)</li>"
            }
            body += "</ol>"
        }

        if let details = recipe.sausageDetails, details.hasAnyValue {
            body += "<h2>Fachdaten &middot; Wurst &amp; R&auml;uchern</h2><table class='details'>"
            for (label, value) in sausageRows(details) {
                body += "<tr><td class='det-label'>\(escape(label))</td>"
                body += "<td class='det-value'>\(escape(value))</td></tr>"
            }
            body += "</table>"
            if !details.safetyNotes.isEmpty {
                body += "<div class='safety'><strong>Sicherheit &amp; Hygiene</strong><br/>\(escape(details.safetyNotes))</div>"
            }
        }

        if !recipe.notes.isEmpty {
            body += "<h2>Notizen</h2><p class='notes'>\(escape(recipe.notes))</p>"
        }

        if !recipe.sourceText.isEmpty || recipe.sourceURL != nil {
            var source = ""
            if !recipe.sourceText.isEmpty { source += escape(recipe.sourceText) }
            if let url = recipe.sourceURL {
                if !source.isEmpty { source += "<br/>" }
                source += "<span class='link'>\(escape(url.absoluteString))</span>"
            }
            body += "<div class='source'><strong>Quelle</strong><br/>\(source)</div>"
        }

        body += "<div class='footer'>Erstellt mit RezeptWerk &middot; \(escape(FormatHelpers.shortDate(.now)))</div>"

        return wrapInDocument(body)
    }

    /// Rahmen-Dokument mit dem kompletten Stylesheet im Kochbuch-Look.
    private static func wrapInDocument(_ body: String) -> String {
        """
        <!DOCTYPE html>
        <html><head><meta charset='utf-8'/>
        <style>
        * { -webkit-print-color-adjust: exact; box-sizing: border-box; }
        body { font-family: -apple-system, 'Helvetica Neue', sans-serif; color: #2D2014; font-size: 14px; line-height: 1.5; margin: 0; }
        .eyebrow { font-family: Georgia, 'Times New Roman', serif; text-transform: uppercase; letter-spacing: 1.5px; font-size: 11px; font-weight: bold; color: #B25A20; margin-bottom: 6px; }
        h1 { font-family: Georgia, 'Times New Roman', serif; font-size: 30px; font-weight: bold; margin: 0 0 8px 0; color: #2D2014; }
        .meta { color: #6E5B47; font-size: 13px; margin-bottom: 14px; }
        .stars { color: #B25A20; letter-spacing: 2px; }
        img.cover { width: 100%; max-height: 300px; border-radius: 12px; margin: 8px 0 16px 0; }
        .tags { margin-bottom: 6px; }
        .tag { display: inline-block; background: #F0E7D8; color: #6E5B47; border-radius: 10px; padding: 2px 10px; font-size: 11px; margin: 0 4px 5px 0; }
        h2 { font-family: Georgia, 'Times New Roman', serif; font-size: 19px; color: #2D2014; margin: 24px 0 6px 0; padding-bottom: 4px; border-bottom: 3px solid #B25A20; display: inline-block; }
        table { width: 100%; border-collapse: collapse; margin-top: 6px; }
        table.ingredients td { padding: 5px 2px; border-bottom: 1px solid #EDE3D2; vertical-align: top; }
        td.amount { color: #B25A20; font-weight: bold; width: 120px; white-space: nowrap; }
        ol.steps { margin: 8px 0 0 0; padding: 0; counter-reset: step; list-style: none; }
        ol.steps li { position: relative; padding: 2px 0 14px 40px; counter-increment: step; }
        ol.steps li:before { content: counter(step); position: absolute; left: 0; top: 0; width: 27px; height: 27px; line-height: 25px; text-align: center; font-family: Georgia, serif; font-weight: bold; font-size: 14px; color: #B25A20; border: 1.5px solid #B25A20; border-radius: 50%; }
        .timer { color: #B25A20; font-size: 12px; white-space: nowrap; }
        table.details td { padding: 5px 2px; border-bottom: 1px solid #EDE3D2; vertical-align: top; }
        td.det-label { color: #6E5B47; width: 190px; }
        td.det-value { font-weight: 600; }
        .safety { background: #F7ECE0; border: 1px solid #E2C3A8; border-radius: 10px; padding: 12px 14px; margin-top: 14px; font-size: 13px; }
        .notes { white-space: pre-wrap; }
        .source { margin-top: 20px; font-size: 13px; color: #6E5B47; }
        .link { color: #B25A20; }
        .footer { margin-top: 30px; padding-top: 10px; border-top: 1px solid #EDE3D2; text-align: center; color: #A4937D; font-size: 11px; }
        </style></head>
        <body>\(body)</body></html>
        """
    }

    // MARK: Gemeinsame Helfer

    /// Fachdaten-Zeilen (ohne Sicherheitshinweis — der wird separat
    /// hervorgehoben). Wird von Text- und PDF-Ausgabe geteilt.
    private static func sausageRows(_ d: SausageSmokingDetails) -> [(String, String)] {
        var rows: [(String, String)] = []
        if let v = FormatHelpers.amountText(d.meatWeightKg) { rows.append(("Fleischmenge", "\(v) kg")) }
        if !d.seasoningPerKg.isEmpty { rows.append(("Gewürze je kg", d.seasoningPerKg)) }
        if let v = FormatHelpers.amountText(d.npsGramsPerKg) { rows.append(("Nitritpökelsalz", "\(v) g/kg")) }
        if !d.cutterAids.isEmpty { rows.append(("Kutterhilfsmittel", d.cutterAids)) }
        if let v = FormatHelpers.amountText(d.iceWaterPercent) { rows.append(("Schüttung/Eis", "\(v) %")) }
        if !d.casing.isEmpty { rows.append(("Darm/Kaliber", d.casing)) }
        if d.smokingMethod != .none { rows.append(("Räucherart", d.smokingMethod.label)) }
        if let v = d.smokingTemperatureCelsius { rows.append(("Räuchertemperatur", "\(v) °C")) }
        if let v = d.smokingTimeMinutes { rows.append(("Räucherzeit", FormatHelpers.minutesText(v))) }
        if let v = d.scaldingTemperatureCelsius { rows.append(("Brühtemperatur", "\(v) °C")) }
        if let v = d.coreTemperatureCelsius { rows.append(("Kerntemperatur", "\(v) °C")) }
        if let v = d.curingDays { rows.append(("Reifezeit", v == 1 ? "1 Tag" : "\(v) Tage")) }
        if let v = d.dryingDays { rows.append(("Trocknungszeit", v == 1 ? "1 Tag" : "\(v) Tage")) }
        return rows
    }

    private static func amountText(_ ingredient: Ingredient) -> String {
        var parts: [String] = []
        if let amount = FormatHelpers.amountText(ingredient.amount) { parts.append(amount) }
        if !ingredient.unit.isEmpty { parts.append(ingredient.unit) }
        return parts.joined(separator: " ")
    }

    private static func stars(_ rating: Int) -> String {
        String(repeating: "★", count: rating) + String(repeating: "☆", count: max(0, 5 - rating))
    }

    /// Entfernt für Dateinamen ungeeignete Zeichen.
    private static func sanitizedFileName(_ title: String) -> String {
        let invalid = CharacterSet(charactersIn: "/\\:?%*|\"<>")
        let cleaned = title.components(separatedBy: invalid)
            .joined(separator: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? "Rezept" : cleaned
    }

    /// Maskiert HTML-Sonderzeichen, damit Rezepttexte nicht das Layout
    /// zerschießen.
    private static func escape(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}

/// Wartet, bis eine `WKWebView` ihr HTML fertig geladen hat — als
/// `async`-Funktion verpackt. Resümiert auch bei Ladefehlern, damit die
/// PDF-Erzeugung nie hängen bleibt (das HTML kommt ohnehin ohne Netz aus).
@MainActor
private final class PDFLoadWatcher: NSObject, WKNavigationDelegate {
    private var continuation: CheckedContinuation<Void, Never>?
    private var didLoad = false

    func waitUntilLoaded() async {
        await withCheckedContinuation { continuation in
            if didLoad {
                continuation.resume()
            } else {
                self.continuation = continuation
            }
        }
    }

    private func finish() {
        didLoad = true
        continuation?.resume()
        continuation = nil
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        finish()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        finish()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        finish()
    }
}
