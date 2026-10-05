import Foundation

// MARK: - 材料

// 材料1つ分のデータ（例：薄力粉 100g）
struct Ingredient: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var amount: Double
    var unit: String
    var group: String? = nil
}

extension Ingredient {
    // 選べる単位
    static let selectableUnits = [
        "g", "kg", "mg", "ml", "L", "cc",
        "小さじ", "大さじ", "カップ",
        "個", "本", "枚", "片", "丁", "玉", "尾", "切れ",
        "袋", "缶", "パック", "束", "株", "房", "節", "合",
        "適量", "少々", "ひとつまみ", "分量外"
    ]

    var isQualitativeAmount: Bool {
        ["適量", "少々", "ひとつまみ", "分量外"].contains(unit)
    }

    // 人数変更後の分量を表示用の文字にする
    func amountDescription(scale: Double = 1) -> String {
        if unit == "分量外" {
            return "（\(localizedIngredientUnit(unit))）"
        }

        if isQualitativeAmount {
            return localizedIngredientUnit(unit)
        }

        let calculatedAmount = amount * scale
        return "\(calculatedAmount.recipeAmount) \(localizedIngredientUnit(unit))"
    }
}

// MARK: - レシピ

// レシピ1つ分のデータ
struct Recipe: Identifiable, Codable, Hashable {
    var id = UUID()
    var recipeNumber: Int? = nil
    var title: String
    var category: String
    var servings: Int
    var yieldAmount: Double? = nil
    var yieldUnit: String? = nil
    var cookingMinutes: Int
    var preheatTemperature: Int? = nil
    var ingredients: [Ingredient]
    var steps: [String]
    var notes: String
    var photoFilename: String? = nil
    var isFavorite: Bool
}

extension Double {
    // 1.0は「1」、1.25は「1.25」で表示
    var recipeAmount: String {
        if self == rounded() {
            return String(Int(self))
        }
        return formatted(.number.precision(.fractionLength(0...2)))
    }
}

extension Recipe {
    static let standardCategories = ["和食", "製菓", "パン", "中華", "フレンチ", "イタリアン", "エスニック", "洋食", "その他"]
    static let yieldUnits = ["人分", "個", "枚", "本", "台", "号", "直径cm", "天板cm²"]

    var recipeNumberText: String {
        guard let recipeNumber else { return NSLocalizedString("未採番", comment: "Recipe number not assigned") }
        return String(format: "No.%03d", recipeNumber)
    }

    var baseYieldAmount: Double {
        max(yieldAmount ?? Double(servings), 0.01)
    }

    var baseYieldUnit: String {
        yieldUnit ?? "人分"
    }

    var yieldDescription: String {
        yieldDescription(for: baseYieldAmount)
    }

    func yieldDescription(for amount: Double) -> String {
        if baseYieldUnit == "直径cm" {
            return String(format: NSLocalizedString("直径 %@cm", comment: "Cake diameter"), amount.recipeAmount)
        }
        return String(
            format: NSLocalizedString("%@ %@", comment: "Yield amount and unit"),
            amount.recipeAmount,
            localizedYieldUnit(baseYieldUnit)
        )
    }

    func scale(for targetYield: Double) -> Double {
        // 0で割らないための最低値
        let safeTargetYield = max(targetYield, 0.01)
        let ratio = safeTargetYield / baseYieldAmount

        // 丸型は直径ではなく面積に合わせて計算
        let usesRoundPan = ["号", "直径cm"].contains(baseYieldUnit)
        if usesRoundPan {
            return ratio * ratio
        }

        return ratio
    }

    static let sample = Recipe(
        recipeNumber: 1,
        title: "鶏肉のトマト煮込み",
        category: "洋食",
        servings: 2,
        cookingMinutes: 35,
        ingredients: [
            Ingredient(name: "鶏もも肉", amount: 300, unit: "g"),
            Ingredient(name: "玉ねぎ", amount: 0.5, unit: "個"),
            Ingredient(name: "カットトマト缶", amount: 200, unit: "g"),
            Ingredient(name: "オリーブオイル", amount: 1, unit: "大さじ"),
            Ingredient(name: "塩", amount: 2, unit: "g")
        ],
        steps: [
            "鶏もも肉を一口大に切り、塩をなじませる。",
            "鍋にオリーブオイルを熱し、鶏肉の表面を焼く。",
            "薄切りにした玉ねぎを加え、透き通るまで炒める。",
            "カットトマトを加え、弱火で20分煮込む。"
        ],
        notes: "酸味が強いときは、砂糖をひとつまみ加える。",
        isFavorite: true
    )
}

func localizedCategory(_ category: String) -> String {
    NSLocalizedString(category, comment: "Recipe category")
}

func localizedYieldUnit(_ unit: String) -> String {
    NSLocalizedString(unit, comment: "Recipe yield unit")
}

func localizedIngredientUnit(_ unit: String) -> String {
    NSLocalizedString(unit, comment: "Ingredient unit")
}
