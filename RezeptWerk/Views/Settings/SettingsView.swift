import SwiftUI
import SwiftData

/// Die Einstellungen: Erscheinungsbild, Kochmodus-Schriftgröße,
/// Beispielrezepte, Import-Tipps und App-Info.
struct SettingsView: View {

    @AppStorage(SettingsKeys.appearance)
    private var appearanceRaw = AppearanceSetting.system.rawValue

    @AppStorage(SettingsKeys.cookingFontSize)
    private var cookingFontSizeRaw = CookingFontSize.normal.rawValue

    @AppStorage(SettingsKeys.keepScreenOn)
    private var keepScreenOn = false

    @Environment(\.modelContext) private var modelContext

    @Query private var allRecipes: [Recipe]

    @State private var showReloadConfirmation = false
    @State private var showReloadedToast = false

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            Form {
                helpSection
                appearanceSection
                screenSection
                cookingModeSection
                CloudBackupSettingsView()
                dataSection
                importTipsSection
                aboutSection
                websiteSection
            }
            .navigationTitle("Einstellungen")
            .confirmationDialog(
                "Beispielrezepte neu laden?",
                isPresented: $showReloadConfirmation,
                titleVisibility: .visible
            ) {
                Button("Neu laden") {
                    SampleDataService.reloadSampleRecipes(context: modelContext)
                    showReloadedToast = true
                }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Nur die mitgelieferten Beispielrezepte werden ersetzt. Deine eigenen Rezepte bleiben unberührt.")
            }
            .alert("Beispielrezepte wurden neu geladen", isPresented: $showReloadedToast) {
                Button("Alles klar") {}
            }
        }
    }

    // MARK: Abschnitte

    private var helpSection: some View {
        Section {
            NavigationLink {
                HelpView()
            } label: {
                Label("Anleitung & Hilfe", systemImage: "book.pages")
            }
        }
    }

    private var appearanceSection: some View {
        Section("Erscheinungsbild") {
            Picker("Darstellung", selection: $appearanceRaw) {
                ForEach(AppearanceSetting.allCases) { setting in
                    Text(setting.label).tag(setting.rawValue)
                }
            }
        }
    }

    private var screenSection: some View {
        Section {
            Toggle("Bildschirm immer an", isOn: $keepScreenOn)
        } header: {
            Text("Bildschirm")
        } footer: {
            Text("Solange RezeptWerk geöffnet ist, wird der Bildschirm nicht automatisch dunkel — praktisch in der Küche. Verbraucht etwas mehr Akku. Im Kochmodus bleibt der Bildschirm immer an, unabhängig von dieser Einstellung.")
        }
    }

    private var cookingModeSection: some View {
        Section {
            Picker("Schriftgröße", selection: $cookingFontSizeRaw) {
                ForEach(CookingFontSize.allCases) { size in
                    Text(size.label).tag(size.rawValue)
                }
            }
            .pickerStyle(.segmented)

            // Live-Vorschau der gewählten Größe.
            Text("Das Steak wenden und weitere 90 Sekunden grillen.")
                .font(AppTypography.cookingStep(
                    scale: (CookingFontSize(rawValue: cookingFontSizeRaw) ?? .normal).scale * 0.7
                ))
                .foregroundStyle(AppColors.textPrimary)
                .padding(.vertical, AppSpacing.xs)
        } header: {
            Text("Kochmodus")
        } footer: {
            Text("So groß erscheint der Text im Kochmodus (Vorschau verkleinert).")
        }
    }

    private var dataSection: some View {
        Section {
            LabeledContent("Speicherort", value: "Lokal auf diesem Gerät")
            LabeledContent("Rezepte", value: "\(allRecipes.count)")

            Button("Beispielrezepte neu laden") {
                showReloadConfirmation = true
            }
            .foregroundStyle(AppColors.copper)
        } header: {
            Text("Deine Daten")
        } footer: {
            Text("RezeptWerk speichert alles ausschließlich auf deinem Gerät — keine Cloud, kein Konto, keine Weitergabe. Ein Gerätebackup (z. B. über den Finder) sichert auch deine Rezepte.")
        }
    }

    private var importTipsSection: some View {
        Section("Import-Tipps") {
            DisclosureGroup("Foto & Scan") {
                tipText("Gutes Licht, gerade von oben fotografieren, scharfer Text. Der Kamera-Scanner begradigt Seiten automatisch. Nach der Erkennung kannst du in der Vorschau alles korrigieren.")
            }
            DisclosureGroup("PDF") {
                tipText("Normale Text-PDFs werden direkt gelesen. Gescannte PDFs laufen automatisch durch die Texterkennung (bis 10 Seiten). Passwortgeschützte PDFs werden nicht unterstützt.")
            }
            DisclosureGroup("Webseite") {
                tipText("Die meisten Rezeptseiten funktionieren direkt per Link. Klappt eine Seite nicht, kopiere den Rezepttext und nutze „Text einfügen“ — das funktioniert immer.")
            }
            DisclosureGroup("Text einfügen") {
                tipText("Überschriften wie „Zutaten“ und „Zubereitung“ im kopierten Text verbessern die Erkennung deutlich. Mengenangaben am Zeilenanfang („250 g Mehl“) werden automatisch zerlegt.")
            }
        }
    }

    private var aboutSection: some View {
        Section("Über RezeptWerk") {
            LabeledContent("Version", value: appVersion)
            Text("RezeptWerk ist dein digitales Rezept-Werkzeug — fürs Kochen, Grillen, Wursten und Räuchern. Handwerklich gebaut, ohne Schnickschnack.")
                .font(AppTypography.secondary)
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    /// Die Webseite hinter RezeptWerk — kurze Vorstellung und Absprung.
    private var websiteSection: some View {
        Section {
            Text("Leckeres aus der Küche von Mattes und Reini: ausführliche Rezepte zum Nachkochen — von bayerischer Hausmannskost über BBQ bis zur internationalen Küche — und spannendes Hintergrundwissen aus der Rubrik „Die Chemie des Kochens“.")
                .font(AppTypography.secondary)
                .foregroundStyle(AppColors.textSecondary)

            if let url = URL(string: "https://kochenmitreima.de") {
                Link(destination: url) {
                    Label("kochenmitreima.de besuchen", systemImage: "safari")
                        .font(AppTypography.body.weight(.medium))
                }
                .foregroundStyle(AppColors.copper)
            }
        } header: {
            Text("Kochen mit ReiMa")
        } footer: {
            Text("Öffnet die Webseite in deinem Browser.")
        }
    }

    private func tipText(_ text: String) -> some View {
        Text(text)
            .font(AppTypography.secondary)
            .foregroundStyle(AppColors.textSecondary)
            .padding(.vertical, AppSpacing.xs)
    }
}

#Preview {
    SettingsView()
        .modelContainer(PreviewSupport.container)
}
