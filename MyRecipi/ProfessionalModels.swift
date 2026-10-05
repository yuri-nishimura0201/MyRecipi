import Foundation

struct IngredientProfile: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var packagePrice: Double = 0
    var packageAmount: Double = 100
    var packageUnit: String = "g"
    var yieldPercent: Double = 100
    var allergens: String = ""
    var substitute: String = ""
    var refrigeratedDays: Int = 0
    var frozenDays: Int = 0

    var usableRatio: Double { max(yieldPercent, 1) / 100 }
}

struct CookingRecord: Identifiable, Codable, Hashable {
    var id = UUID()
    var recipeID: UUID
    var createdAt = Date()
    var preparedWeight: Double = 0
    var actualYield: Double = 0
    var bakeTemperature: Int = 0
    var bakeMinutes: Int = 0
    var rating: Int = 3
    var notes: String = ""
    var photoFilename: String? = nil

    var lossPercent: Double? {
        guard preparedWeight > 0, actualYield >= 0 else { return nil }
        return max(0, (preparedWeight - actualYield) / preparedWeight * 100)
    }
}

struct RecipeVersion: Identifiable, Codable, Hashable {
    var id = UUID()
    var savedAt = Date()
    var label: String
    var recipe: Recipe
}

struct DeletedRecipe: Identifiable, Codable, Hashable {
    var id: UUID { recipe.id }
    var deletedAt = Date()
    var recipe: Recipe
}

struct ProfessionalData: Codable {
    var ingredientProfiles: [IngredientProfile] = []
    var cookingRecords: [CookingRecord] = []
    var recipeVersions: [RecipeVersion] = []
    var recentlyDeleted: [DeletedRecipe] = []
    var shoppingRecipeIDs: Set<UUID> = []
    var checkedShoppingKeys: Set<String> = []
    var checkedPrepKeys: Set<String> = []
    var stepPhotoFilenames: [String: String] = [:]
}

struct MyRecipiBackup: Codable {
    var exportedAt = Date()
    var recipes: [Recipe]
    var professionalData: ProfessionalData
}

struct ShoppingItem: Identifiable, Hashable {
    var id: String { key }
    let key: String
    let name: String
    let amount: Double
    let unit: String
    let recipeTitles: [String]
}

enum KitchenKnowledge {
    private static let allergenRules: [(words: [String], label: String)] = [
        (["卵", "oeuf", "œuf"], "卵"),
        (["牛乳", "乳", "バター", "チーズ", "クリーム", "lait", "beurre", "fromage", "crème"], "乳"),
        (["小麦", "薄力粉", "中力粉", "強力粉", "パン", "farine"], "小麦"),
        (["そば", "sarrasin"], "そば"),
        (["落花生", "ピーナッツ", "cacahuète"], "落花生"),
        (["えび", "海老", "crevette"], "えび"),
        (["かに", "蟹", "crabe"], "かに"),
        (["くるみ", "noix"], "くるみ"),
        (["アーモンド", "amande"], "アーモンド"),
        (["ごま", "sésame"], "ごま"),
        (["大豆", "豆腐", "味噌", "しょうゆ", "soja"], "大豆")
    ]

    static func allergens(for ingredientName: String, custom: String = "") -> [String] {
        var values = allergenRules.compactMap { rule in
            rule.words.contains { ingredientName.localizedCaseInsensitiveContains($0) } ? rule.label : nil
        }
        values += custom.split(separator: "、").map(String.init)
        return Array(Set(values)).sorted()
    }

    static func substitute(for name: String) -> String? {
        let rules: [(words: [String], value: String)] = [
            (["薄力粉"], "米粉（食感が変わるため吸水量を調整）"),
            (["牛乳"], "豆乳またはオーツミルク"),
            (["生クリーム"], "植物性クリームまたは濃いココナッツミルク"),
            (["バター"], "同量のマーガリン、または用途に合わせた植物油"),
            (["卵"], "用途によりアクアファバ、豆腐、バナナなど"),
            (["白ワイン"], "同量のだし＋少量の酢またはレモン汁"),
            (["片栗粉"], "コーンスターチ"),
            (["ゼラチン"], "寒天またはアガー（凝固特性が異なる）")
        ]
        return rules.first { $0.words.contains(where: name.localizedCaseInsensitiveContains) }?.value
    }

    static func normalizedAmount(_ amount: Double, unit: String) -> (Double, String) {
        switch unit.lowercased() {
        case "kg": return (amount * 1_000, "g")
        case "mg": return (amount / 1_000, "g")
        case "l": return (amount * 1_000, "ml")
        case "cc": return (amount, "ml")
        case "大さじ": return (amount * 15, "ml")
        case "小さじ": return (amount * 5, "ml")
        case "カップ": return (amount * 200, "ml")
        default: return (amount, unit)
        }
    }
}
