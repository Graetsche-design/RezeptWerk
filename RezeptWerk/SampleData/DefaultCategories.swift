import Foundation

/// Bauplan für eine Standard-Kategorie samt Unterkategorien.
struct CategoryBlueprint {
    let name: String
    let icon: String
    let subcategories: [String]
}

/// Die zwölf Standard-Kategorien von RezeptWerk.
///
/// Sie werden beim ersten App-Start angelegt (`SampleDataService`).
/// Der Nutzer kann sie behalten, ergänzen oder eigene hinzufügen.
enum DefaultCategories {

    static let all: [CategoryBlueprint] = [
        CategoryBlueprint(name: "Fleisch", icon: "frying.pan", subcategories: ["Rind", "Schwein", "Lamm", "Wild"]),
        CategoryBlueprint(name: "Geflügel", icon: "bird", subcategories: ["Hähnchen", "Pute", "Ente"]),
        CategoryBlueprint(name: "Fisch", icon: "fish", subcategories: ["Süßwasserfisch", "Meeresfisch", "Meeresfrüchte"]),
        CategoryBlueprint(name: "Grillen", icon: "flame", subcategories: ["Steaks", "Burger", "Spieße", "Dutch Oven", "Smoker"]),
        CategoryBlueprint(name: "Wurst & Räuchern", icon: "smoke", subcategories: ["Brühwurst", "Rohwurst", "Kochwurst", "Räucherfleisch", "Schinken"]),
        CategoryBlueprint(name: "Suppen & Eintöpfe", icon: "stove", subcategories: ["Klare Suppen", "Cremesuppen", "Eintöpfe"]),
        CategoryBlueprint(name: "Beilagen", icon: "carrot", subcategories: ["Kartoffeln", "Reis & Nudeln", "Gemüse", "Salate"]),
        CategoryBlueprint(name: "Saucen", icon: "drop.fill", subcategories: ["Grillsaucen", "Marinaden", "Dips", "Klassiker"]),
        CategoryBlueprint(name: "Backen", icon: "oven", subcategories: ["Brot", "Kuchen", "Gebäck", "Pizza & Flammkuchen"]),
        CategoryBlueprint(name: "Desserts", icon: "birthday.cake", subcategories: ["Cremes & Pudding", "Eis", "Obst"]),
        CategoryBlueprint(name: "Kindergerichte", icon: "teddybear", subcategories: ["Pasta", "Klassiker", "Süßes"]),
        CategoryBlueprint(name: "Getränke", icon: "mug", subcategories: ["Alkoholfrei", "Heißgetränke", "Cocktails"]),
    ]
}
