import Foundation
import SwiftData

/// Die sechs mitgelieferten Beispielrezepte.
///
/// Sie zeigen die ganze Bandbreite der App: schnelles Grillrezept mit
/// Schritt-Timern, ein komplettes Wurst-Rezept mit Fachdaten-Block,
/// Klassiker, Kindergericht, Dutch Oven und ein Getränk.
@MainActor
enum SampleRecipes {

    /// Legt alle Beispielrezepte an. Erwartet, dass die Standard-Kategorien
    /// bereits existieren (macht `SampleDataService.seedIfNeeded`).
    static func insert(into context: ModelContext) {
        let categories = (try? context.fetch(FetchDescriptor<RecipeCategory>())) ?? []

        func category(_ name: String) -> RecipeCategory? {
            categories.first { $0.name == name }
        }

        func subcategory(_ categoryName: String, _ subName: String) -> RecipeSubcategory? {
            category(categoryName)?.sortedSubcategories.first { $0.name == subName }
        }

        /// Baut ein Rezept mit allen gemeinsamen Feldern zusammen.
        func makeRecipe(
            title: String,
            category categoryName: String,
            subcategory subName: String?,
            servings: Int,
            prep: Int?,
            cook: Int?,
            rest: Int? = nil,
            difficulty: Difficulty,
            rating: Int,
            favorite: Bool = false,
            mealTypes: [MealType] = [],
            tags: [String],
            notes: String,
            daysAgo: Double,
            ingredients: [(Double?, String, String)],
            steps: [(String, Int?)]
        ) -> Recipe {
            let recipe = Recipe(title: title)
            context.insert(recipe)

            recipe.category = category(categoryName)
            if let subName {
                recipe.subcategory = subcategory(categoryName, subName)
            }
            recipe.servings = servings
            recipe.prepMinutes = prep
            recipe.cookMinutes = cook
            recipe.restMinutes = rest
            recipe.difficulty = difficulty
            recipe.rating = rating
            recipe.isFavorite = favorite
            recipe.suitableMealTypes = mealTypes
            recipe.notes = notes
            recipe.isSample = true
            // Gestaffelte Daten, damit „Zuletzt hinzugefügt“ lebendig aussieht.
            recipe.createdAt = Date.now.addingTimeInterval(-86_400 * daysAgo)
            recipe.updatedAt = recipe.createdAt

            recipe.ingredients = ingredients.enumerated().map { index, row in
                Ingredient(amount: row.0, unit: row.1, name: row.2, sortIndex: index)
            }
            recipe.steps = steps.enumerated().map { index, row in
                RecipeStep(text: row.0, sortIndex: index, timerSeconds: row.1)
            }
            recipe.tags = RecipeImportService.resolveTags(names: tags, in: context)
            return recipe
        }

        // MARK: 1. Rib-Eye-Steak vom Grill (Timer-Demo)

        let steak = makeRecipe(
            title: "Rib-Eye-Steak vom Grill",
            category: "Grillen", subcategory: "Steaks",
            servings: 2, prep: 10, cook: 8, rest: 5,
            difficulty: .easy, rating: 5, favorite: true,
            mealTypes: [.dinner],
            tags: ["Grill", "schnell"],
            notes: "Das Fleisch eine Stunde vor dem Grillen aus dem Kühlschrank nehmen — so gart es gleichmäßiger. Gepfeffert wird erst nach dem Grillen, sonst verbrennt der Pfeffer.",
            daysAgo: 1,
            ingredients: [
                (2, "Stück", "Rib-Eye-Steaks (à ca. 300 g)"),
                (1, "EL", "grobes Meersalz"),
                (1, "TL", "schwarzer Pfeffer, frisch gemahlen"),
                (1, "Zweig", "Rosmarin"),
                (2, "EL", "Butter"),
            ],
            steps: [
                ("Die Steaks eine Stunde vor dem Grillen aus dem Kühlschrank nehmen und gründlich trocken tupfen.", nil),
                ("Den Grill für starke direkte Hitze vorbereiten (250–280 °C). Eine indirekte Zone freihalten.", nil),
                ("Die Steaks von beiden Seiten kräftig salzen.", nil),
                ("Erste Seite: 90 Sekunden grillen, um 90 Grad drehen (Grillmuster) und weitere 90 Sekunden grillen.", 90),
                ("Wenden und die zweite Seite genauso grillen: 2 × 90 Sekunden.", 90),
                ("In den indirekten Bereich ziehen und auf 54–56 °C Kerntemperatur ziehen lassen (medium).", 240),
                ("Mit Butter und Rosmarin belegen und 5 Minuten ruhen lassen. Erst jetzt pfeffern, dann quer zur Faser aufschneiden.", 300),
            ]
        )
        _ = steak

        // MARK: 2. Käsekrakauer (Wurst & Räuchern mit Fachdaten)

        let krakauer = makeRecipe(
            title: "Käsekrakauer",
            category: "Wurst & Räuchern", subcategory: "Brühwurst",
            servings: 10, prep: 120, cook: 75,
            difficulty: .medium, rating: 4,
            mealTypes: [.lunch, .dinner],
            tags: ["Wurst", "Räuchern"],
            notes: "Funktioniert auch mit geräuchertem Käse. Wer es pikanter mag: zusätzlich 1 g/kg Chiliflocken. Die Würste halten vakuumiert gut zwei Wochen im Kühlschrank.",
            daysAgo: 4,
            ingredients: [
                (1.5, "kg", "Schweineschulter, gut gekühlt"),
                (0.5, "kg", "Schweinebauch ohne Schwarte"),
                (400, "g", "Emmentaler, in 1-cm-Würfeln"),
                (300, "g", "Eiswasser/Eisschnee"),
                (nil, "", "Gewürze & Nitritpökelsalz: Mengen pro kg siehe Fachdaten unten"),
            ],
            steps: [
                ("Das gut gekühlte Fleisch in wolfgerechte Stücke schneiden und durch die 8-mm-Scheibe wolfen.", nil),
                ("Brät mit Eiswasser, Nitritpökelsalz, Gewürzen und Kutterhilfsmittel intensiv kneten bzw. kuttern, bis es deutlich bindet. Die Temperatur dabei unter 12 °C halten.", nil),
                ("Die Käsewürfel zügig und gleichmäßig unterheben.", nil),
                ("Das Brät luftblasenfrei in die vorbereiteten Därme füllen und Würste von etwa 20 cm abdrehen.", nil),
                ("Die Würste eine Stunde bei Raumtemperatur abtrocknen und umröten lassen.", 3600),
                ("Bei etwa 75 °C rund 45 Minuten heißräuchern, bis sie eine satte rotbraune Farbe haben.", 2700),
                ("Bei 76–78 °C brühen, bis die Kerntemperatur von 72 °C erreicht ist (ca. 30 Minuten).", 1800),
                ("In Eiswasser abschrecken, abtrocknen und kühl lagern — oder portionsweise einfrieren.", nil),
            ]
        )
        let krakauerDetails = SausageSmokingDetails()
        krakauerDetails.meatWeightKg = 2.0
        krakauerDetails.seasoningPerKg = "3 g Pfeffer · 2 g Majoran · 1,5 g Knoblauchpulver · 1 g Zucker · 0,5 g Muskat"
        krakauerDetails.npsGramsPerKg = 18
        krakauerDetails.cutterAids = "3 g/kg Kutterhilfsmittel (Phosphat)"
        krakauerDetails.iceWaterPercent = 15
        krakauerDetails.casing = "Schweinedarm, Kaliber 28/30"
        krakauerDetails.smokingMethod = .hot
        krakauerDetails.smokingTimeMinutes = 45
        krakauerDetails.smokingTemperatureCelsius = 75
        krakauerDetails.scaldingTemperatureCelsius = 77
        krakauerDetails.coreTemperatureCelsius = 72
        krakauerDetails.safetyNotes = "Nitritpökelsalz grammgenau abwiegen — niemals nach Gefühl dosieren. Brättemperatur beim Kuttern unter 12 °C halten. Kerntemperatur von 72 °C sicher erreichen. Saubere Arbeitsflächen, sauberes Werkzeug und eine durchgehende Kühlkette sind Pflicht."
        krakauer.sausageDetails = krakauerDetails

        // MARK: 3. Klare Rinderbrühe

        _ = makeRecipe(
            title: "Klare Rinderbrühe",
            category: "Suppen & Eintöpfe", subcategory: "Klare Suppen",
            servings: 6, prep: 20, cook: 180,
            difficulty: .medium, rating: 4,
            mealTypes: [.lunch, .dinner],
            tags: ["Sonntag", "Grundrezept"],
            notes: "Die Basis für Suppen, Saucen und Eintöpfe. Portionsweise einfrieren — hält mindestens drei Monate.",
            daysAgo: 7,
            ingredients: [
                (1.5, "kg", "Rinderknochen (gern Markknochen)"),
                (500, "g", "Beinscheibe"),
                (2, "Stück", "Zwiebeln, halbiert (mit Schale)"),
                (1, "Bund", "Suppengrün"),
                (2, "Stück", "Lorbeerblätter"),
                (6, "Stück", "Pfefferkörner"),
                (1, "EL", "Salz"),
                (3, "l", "kaltes Wasser"),
            ],
            steps: [
                ("Knochen und Beinscheibe kalt abspülen und mit dem kalten Wasser in einen großen Topf geben.", nil),
                ("Langsam erhitzen und den aufsteigenden grauen Schaum sorgfältig abschöpfen.", nil),
                ("Die Zwiebelhälften mit der Schnittfläche in einer Pfanne ohne Fett dunkel anrösten — das gibt der Brühe Farbe.", nil),
                ("Zwiebeln, grob zerteiltes Suppengrün, Lorbeer und Pfefferkörner zugeben.", nil),
                ("Drei Stunden knapp unter dem Siedepunkt ziehen lassen — die Brühe darf nie sprudelnd kochen, sonst wird sie trüb.", 10800),
                ("Durch ein feines Tuch passieren und mit Salz abschmecken.", nil),
            ]
        )

        // MARK: 4. Kinder-Pasta mit Tomatensauce

        let pasta = makeRecipe(
            title: "Kinder-Pasta mit Tomatensauce",
            category: "Kindergerichte", subcategory: "Pasta",
            servings: 4, prep: 10, cook: 20,
            difficulty: .easy, rating: 5, favorite: true,
            mealTypes: [.lunch, .dinner],
            tags: ["Kinder", "schnell"],
            notes: "Beliebter Trick: eine fein geriebene Möhre in der Sauce mitkochen — schmeckt süßlich und fällt nicht auf.",
            daysAgo: 10,
            ingredients: [
                (400, "g", "Nudeln (z. B. Fusilli)"),
                (1, "Stück", "Zwiebel"),
                (1, "EL", "Olivenöl"),
                (700, "ml", "passierte Tomaten"),
                (1, "Prise", "Zucker"),
                (100, "g", "geriebener Käse"),
                (nil, "", "Salz"),
            ],
            steps: [
                ("Die Zwiebel fein würfeln und im Olivenöl glasig dünsten.", nil),
                ("Passierte Tomaten zugeben und mit Salz und einer Prise Zucker würzen.", nil),
                ("Die Sauce 15 Minuten leise köcheln lassen.", 900),
                ("Währenddessen die Nudeln nach Packungsangabe kochen.", 600),
                ("Nudeln abgießen, mit der Sauce mischen und mit Käse bestreut servieren.", nil),
            ]
        )
        pasta.lastCookedAt = Date.now.addingTimeInterval(-86_400 * 2)

        // MARK: 5. Dutch-Oven-Gulasch

        _ = makeRecipe(
            title: "Dutch-Oven-Gulasch",
            category: "Grillen", subcategory: "Dutch Oven",
            servings: 6, prep: 30, cook: 150,
            difficulty: .medium, rating: 5,
            mealTypes: [.dinner],
            tags: ["Dutch Oven", "draußen", "Sonntag"],
            notes: "Richtwert Briketts für einen 12er Dutch Oven: 8 unten, 14 auf dem Deckel. Nach 90 Minuten frische Briketts nachlegen.",
            daysAgo: 13,
            ingredients: [
                (1.5, "kg", "Rindergulasch"),
                (800, "g", "Zwiebeln, grob gewürfelt"),
                (2, "EL", "Butterschmalz"),
                (3, "EL", "Tomatenmark"),
                (2, "EL", "Paprikapulver, edelsüß"),
                (1, "TL", "Kümmel, gemahlen"),
                (2, "Stück", "Knoblauchzehen"),
                (500, "ml", "Rinderfond"),
                (2, "Stück", "rote Paprika, in Streifen"),
            ],
            steps: [
                ("Den Dutch Oven mit Deckel über Briketts ordentlich vorheizen.", nil),
                ("Das Fleisch portionsweise im Butterschmalz scharf anbraten und herausnehmen.", nil),
                ("Die Zwiebeln im Bratfett goldbraun rösten. Tomatenmark und Paprikapulver kurz mitrösten — nicht verbrennen lassen.", nil),
                ("Fleisch zurückgeben, mit Rinderfond auffüllen, Kümmel und gepressten Knoblauch zugeben.", nil),
                ("Mit Deckel (Briketts unten und oben) 2,5 Stunden sanft schmoren, gelegentlich umrühren.", 9000),
                ("Die Paprikastreifen zugeben und die letzten 20 Minuten mitschmoren. Mit Salz und Pfeffer abschmecken.", 1200),
            ]
        )

        // MARK: 6. Limetten-Minz-Limonade (alkoholfrei)

        _ = makeRecipe(
            title: "Limetten-Minz-Limonade",
            category: "Getränke", subcategory: "Alkoholfrei",
            servings: 4, prep: 10, cook: nil,
            difficulty: .easy, rating: 4,
            mealTypes: [.snack],
            tags: ["schnell", "Sommer", "Kinder"],
            notes: "Schmeckt am besten eiskalt. Statt Apfelsaft funktioniert auch heller Traubensaft.",
            daysAgo: 16,
            ingredients: [
                (2, "Stück", "Bio-Limetten"),
                (1, "Bund", "frische Minze"),
                (3, "EL", "Zucker"),
                (200, "ml", "naturtrüber Apfelsaft"),
                (800, "ml", "Sprudelwasser, eiskalt"),
                (nil, "", "Eiswürfel"),
            ],
            steps: [
                ("Die Limetten heiß abwaschen. Eine in Scheiben schneiden, die andere auspressen.", nil),
                ("Die Minze waschen und trocken schütteln. Ein paar schöne Blätter zum Garnieren beiseitelegen.", nil),
                ("Limettensaft, Zucker und Minze in einer Karaffe mit einem Löffel leicht andrücken, damit sich die Aromen lösen.", nil),
                ("Mit Apfelsaft und Sprudelwasser auffüllen und kräftig umrühren.", nil),
                ("Mit Eiswürfeln, Limettenscheiben und Minzblättern servieren.", nil),
            ]
        )

        // MARK: Ein paar Beispiel-Einträge für den Wochenplan (diese Woche)

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        func plan(_ recipe: Recipe, dayOffset: Int, _ mealType: MealType) {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: today) else { return }
            context.insert(PlannedMeal(date: day, mealType: mealType, recipe: recipe))
        }
        plan(pasta, dayOffset: 0, .lunch)   // heute Mittag
        plan(steak, dayOffset: 0, .dinner)  // heute Abend
        plan(pasta, dayOffset: 2, .dinner)  // übermorgen
    }
}
