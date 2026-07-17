import UIKit
import UniformTypeIdentifiers

/// Die Teilen-Erweiterung von RezeptWerk.
///
/// Sie erscheint im iOS-Teilen-Menü (z. B. aus Safari, Notizen, Nachrichten
/// oder Instagram). Sie nimmt den geteilten **Link** oder **Text** entgegen,
/// legt ihn in der gemeinsamen App-Gruppe ab und meldet sich kurz zurück.
/// Die eigentliche Erkennung (Vorschau, Speichern) übernimmt dann die
/// Haupt-App beim nächsten Öffnen — so bleibt die Erweiterung schlank und
/// alles läuft über den bereits vorhandenen Import-Ablauf.
@objc(ShareViewController)
final class ShareViewController: UIViewController {

    /// Muss mit der App-Gruppe in den Entitlements übereinstimmen.
    private let appGroupID = "group.de.rezeptwerk.app"

    private let card = UIView()
    private let statusLabel = UILabel()
    private let spinner = UIActivityIndicatorView(style: .medium)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        extractSharedContent()
    }

    // MARK: Inhalt auslesen

    private func extractSharedContent() {
        guard let item = extensionContext?.inputItems.first as? NSExtensionItem,
              let providers = item.attachments, !providers.isEmpty else {
            finish(success: false)
            return
        }

        // Zuerst nach einem Link suchen (z. B. geteilte Webseite/Instagram).
        for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] value, _ in
                let urlString = (value as? URL)?.absoluteString ?? (value as? String)
                self?.save(kind: "url", content: urlString)
            }
            return
        }

        // Sonst nach Text suchen (z. B. markierte Bildunterschrift).
        for provider in providers {
            for type in [UTType.plainText.identifier, UTType.text.identifier]
            where provider.hasItemConformingToTypeIdentifier(type) {
                provider.loadItem(forTypeIdentifier: type, options: nil) { [weak self] value, _ in
                    self?.save(kind: "text", content: value as? String)
                }
                return
            }
        }

        finish(success: false)
    }

    private func save(kind: String, content: String?) {
        DispatchQueue.main.async {
            guard let content,
                  !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  let defaults = UserDefaults(suiteName: self.appGroupID) else {
                self.finish(success: false)
                return
            }
            defaults.set(kind, forKey: "pendingShareKind")
            defaults.set(content, forKey: "pendingShareContent")
            defaults.set(Date(), forKey: "pendingShareDate")
            self.finish(success: true)
        }
    }

    // MARK: Abschluss

    private func finish(success: Bool) {
        spinner.stopAnimating()
        statusLabel.text = success
            ? "Übergeben ✓\nÖffne jetzt RezeptWerk, um das Rezept zu prüfen und zu speichern."
            : "Hier ist leider kein Text oder Link zum Übernehmen dabei."

        DispatchQueue.main.asyncAfter(deadline: .now() + (success ? 1.6 : 2.2)) {
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }

    // MARK: Oberfläche (schlicht, im RezeptWerk-Look)

    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.35)

        card.backgroundColor = UIColor(red: 0.106, green: 0.090, blue: 0.075, alpha: 1) // Räucher-Anthrazit
        card.layer.cornerRadius = 18
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor(red: 0.85, green: 0.50, blue: 0.24, alpha: 0.5).cgColor // Kupfer
        card.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(card)

        let title = UILabel()
        title.text = "RezeptWerk"
        title.font = .systemFont(ofSize: 22, weight: .bold)
        title.textColor = UIColor(red: 0.85, green: 0.50, blue: 0.24, alpha: 1)
        title.textAlignment = .center
        title.translatesAutoresizingMaskIntoConstraints = false

        spinner.color = .white
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()

        statusLabel.text = "Rezept wird übergeben …"
        statusLabel.font = .systemFont(ofSize: 15)
        statusLabel.textColor = UIColor(red: 0.94, green: 0.91, blue: 0.85, alpha: 1)
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [title, spinner, statusLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        NSLayoutConstraint.activate([
            card.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            card.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            card.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            card.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32),
            card.widthAnchor.constraint(lessThanOrEqualToConstant: 360),

            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 28),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -28),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -24),
        ])
    }
}
