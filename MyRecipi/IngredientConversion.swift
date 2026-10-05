import Foundation

// 個数とg・mlをだいたいの量に換算する
// 食材の大きさで変わるので、結果は「目安」として表示
enum IngredientConversion {
    // 食材ごとの1個あたりの重さ
    private struct PieceRule {
        let keywords: [String]
        let gramsByUnit: [String: Double]
    }

    private static let pieceRules: [PieceRule] = [
        PieceRule(keywords: ["うずら卵", "うずらの卵", "ウズラ卵"], gramsByUnit: ["個": 10]),
        PieceRule(keywords: ["卵黄", "黄身"], gramsByUnit: ["個": 18]),
        PieceRule(keywords: ["卵白", "白身"], gramsByUnit: ["個": 32]),
        PieceRule(keywords: ["卵", "たまご", "玉子"], gramsByUnit: ["個": 50]),
        PieceRule(keywords: ["玉ねぎ", "たまねぎ", "タマネギ"], gramsByUnit: ["個": 200, "玉": 200]),
        PieceRule(keywords: ["ペコロス", "小玉ねぎ"], gramsByUnit: ["個": 30]),
        PieceRule(keywords: ["じゃがいも", "ジャガイモ", "馬鈴薯"], gramsByUnit: ["個": 150]),
        PieceRule(keywords: ["さつまいも", "サツマイモ", "薩摩芋"], gramsByUnit: ["本": 250]),
        PieceRule(keywords: ["里芋", "さといも", "サトイモ"], gramsByUnit: ["個": 50]),
        PieceRule(keywords: ["かぼちゃ", "カボチャ", "南瓜"], gramsByUnit: ["個": 1_200]),
        PieceRule(keywords: ["にんじん", "人参", "ニンジン"], gramsByUnit: ["本": 150]),
        PieceRule(keywords: ["大根", "だいこん"], gramsByUnit: ["本": 1_000]),
        PieceRule(keywords: ["かぶ", "カブ", "蕪"], gramsByUnit: ["個": 100]),
        PieceRule(keywords: ["れんこん", "レンコン", "蓮根"], gramsByUnit: ["節": 200]),
        PieceRule(keywords: ["ごぼう", "ゴボウ", "牛蒡"], gramsByUnit: ["本": 150]),
        PieceRule(keywords: ["長ねぎ", "長ネギ", "白ねぎ"], gramsByUnit: ["本": 100]),
        PieceRule(keywords: ["万能ねぎ", "小ねぎ", "青ねぎ"], gramsByUnit: ["束": 100]),
        PieceRule(keywords: ["きゅうり", "キュウリ", "胡瓜"], gramsByUnit: ["本": 100]),
        PieceRule(keywords: ["なす", "ナス", "茄子"], gramsByUnit: ["本": 80]),
        PieceRule(keywords: ["ズッキーニ"], gramsByUnit: ["本": 200]),
        PieceRule(keywords: ["ミニトマト", "プチトマト"], gramsByUnit: ["個": 15]),
        PieceRule(keywords: ["トマト"], gramsByUnit: ["個": 150]),
        PieceRule(keywords: ["ピーマン"], gramsByUnit: ["個": 35]),
        PieceRule(keywords: ["パプリカ"], gramsByUnit: ["個": 150]),
        PieceRule(keywords: ["オクラ"], gramsByUnit: ["本": 10]),
        PieceRule(keywords: ["とうもろこし", "トウモロコシ", "コーン"], gramsByUnit: ["本": 300]),
        PieceRule(keywords: ["キャベツ"], gramsByUnit: ["個": 1_200, "玉": 1_200]),
        PieceRule(keywords: ["白菜"], gramsByUnit: ["個": 2_000, "玉": 2_000]),
        PieceRule(keywords: ["レタス"], gramsByUnit: ["個": 300, "玉": 300]),
        PieceRule(keywords: ["ブロッコリー"], gramsByUnit: ["株": 250]),
        PieceRule(keywords: ["カリフラワー"], gramsByUnit: ["株": 500]),
        PieceRule(keywords: ["ほうれん草", "ホウレンソウ"], gramsByUnit: ["束": 200]),
        PieceRule(keywords: ["小松菜"], gramsByUnit: ["束": 200]),
        PieceRule(keywords: ["水菜"], gramsByUnit: ["束": 200]),
        PieceRule(keywords: ["アスパラガス", "アスパラ"], gramsByUnit: ["本": 20]),
        PieceRule(keywords: ["にんにく", "ニンニク", "大蒜"], gramsByUnit: ["片": 5, "個": 50]),
        PieceRule(keywords: ["しょうが", "生姜", "ショウガ"], gramsByUnit: ["片": 15]),
        PieceRule(keywords: ["マッシュルーム"], gramsByUnit: ["個": 15]),
        PieceRule(keywords: ["しいたけ", "椎茸", "シイタケ"], gramsByUnit: ["個": 20, "枚": 20]),
        PieceRule(keywords: ["エリンギ"], gramsByUnit: ["本": 40]),
        PieceRule(keywords: ["しめじ", "シメジ", "ぶなしめじ"], gramsByUnit: ["株": 100, "パック": 100]),
        PieceRule(keywords: ["えのき", "エノキ", "えのきだけ"], gramsByUnit: ["袋": 100]),
        PieceRule(keywords: ["りんご", "リンゴ", "林檎"], gramsByUnit: ["個": 300]),
        PieceRule(keywords: ["みかん", "ミカン", "蜜柑"], gramsByUnit: ["個": 100]),
        PieceRule(keywords: ["オレンジ"], gramsByUnit: ["個": 200]),
        PieceRule(keywords: ["レモン"], gramsByUnit: ["個": 100]),
        PieceRule(keywords: ["ライム"], gramsByUnit: ["個": 80]),
        PieceRule(keywords: ["バナナ"], gramsByUnit: ["本": 100]),
        PieceRule(keywords: ["キウイ", "キウイフルーツ"], gramsByUnit: ["個": 100]),
        PieceRule(keywords: ["桃", "もも", "モモ"], gramsByUnit: ["個": 250]),
        PieceRule(keywords: ["梨", "なし", "ナシ"], gramsByUnit: ["個": 300]),
        PieceRule(keywords: ["柿"], gramsByUnit: ["個": 200]),
        PieceRule(keywords: ["アボカド"], gramsByUnit: ["個": 170]),
        PieceRule(keywords: ["いちご", "イチゴ", "苺"], gramsByUnit: ["個": 15]),
        PieceRule(keywords: ["豆腐", "とうふ"], gramsByUnit: ["丁": 300]),
        PieceRule(keywords: ["油揚げ"], gramsByUnit: ["枚": 30]),
        PieceRule(keywords: ["厚揚げ"], gramsByUnit: ["枚": 150]),
        PieceRule(keywords: ["こんにゃく", "コンニャク"], gramsByUnit: ["枚": 250]),
        PieceRule(keywords: ["食パン", "トースト"], gramsByUnit: ["枚": 60]),
        PieceRule(keywords: ["スライスチーズ"], gramsByUnit: ["枚": 18]),
        PieceRule(keywords: ["バター"], gramsByUnit: ["個": 200]),
        PieceRule(keywords: ["鶏もも肉", "鶏むね肉", "鶏胸肉"], gramsByUnit: ["枚": 250]),
        PieceRule(keywords: ["ささみ", "鶏ささみ"], gramsByUnit: ["本": 50]),
        PieceRule(keywords: ["手羽先"], gramsByUnit: ["本": 50]),
        PieceRule(keywords: ["手羽元"], gramsByUnit: ["本": 60]),
        PieceRule(keywords: ["ベーコン"], gramsByUnit: ["枚": 20]),
        PieceRule(keywords: ["ハム"], gramsByUnit: ["枚": 15]),
        PieceRule(keywords: ["魚", "鮭", "さけ", "サーモン", "たら", "鱈"], gramsByUnit: ["切れ": 80]),
        PieceRule(keywords: ["えび", "エビ", "海老"], gramsByUnit: ["尾": 15]),
        PieceRule(keywords: ["ほたて", "ホタテ", "帆立"], gramsByUnit: ["個": 25]),
        PieceRule(keywords: ["牡蠣", "かき", "カキ"], gramsByUnit: ["個": 20])
    ]

    private static let millilitersByUnit: [String: Double] = [
        "小さじ": 5,
        "小匙": 5,
        "tsp": 5,
        "大さじ": 15,
        "大匙": 15,
        "tbsp": 15,
        "カップ": 200,
        "cup": 200,
        "ml": 1,
        "mL": 1,
        "cc": 1,
        "dl": 100,
        "dL": 100,
        "l": 1_000,
        "L": 1_000
    ]

    // 換算できない食材はnilにする
    static func estimate(for ingredient: Ingredient, amount: Double) -> String? {
        guard amount > 0 else { return nil }
        let unit = ingredient.unit.trimmingCharacters(in: .whitespacesAndNewlines)

        // 小さじ・大さじ・カップをmlに直す
        if let multiplier = millilitersByUnit[unit], unit.lowercased() != "ml", unit.lowercased() != "cc" {
            return estimateText(value: amount * multiplier, unit: "ml")
        }

        // g・kg・mgから個数を出す
        if unit == "kg" {
            if let pieceEstimate = pieceEstimate(for: ingredient.name, grams: amount * 1_000) {
                return pieceEstimate
            }
            return estimateText(value: amount * 1_000, unit: "g")
        }
        if unit == "g" {
            return pieceEstimate(for: ingredient.name, grams: amount)
        }
        if unit == "mg" {
            return pieceEstimate(for: ingredient.name, grams: amount / 1_000)
        }

        // 個・本・枚からだいたいの重さを出す
        guard let rule = pieceRules.first(where: { rule in
            rule.keywords.contains { ingredient.name.localizedCaseInsensitiveContains($0) }
        }), let grams = rule.gramsByUnit[unit] else { return nil }

        return estimateText(value: amount * grams, unit: "g")
    }

    private static func pieceEstimate(for ingredientName: String, grams: Double) -> String? {
        let processedWords = ["缶", "ペースト", "ピューレ", "ソース", "ジュース", "パウダー", "粉末", "乾燥", "冷凍", "水煮"]
        guard !processedWords.contains(where: ingredientName.localizedCaseInsensitiveContains) else { return nil }
        guard let rule = pieceRules.first(where: { rule in
            rule.keywords.contains { ingredientName.localizedCaseInsensitiveContains($0) }
        }) else { return nil }
        let preferredUnits = ["個", "本", "枚", "片", "丁", "玉", "尾", "切れ", "株", "束", "袋", "パック", "節"]
        guard let unit = preferredUnits.first(where: { rule.gramsByUnit[$0] != nil }),
              let gramsPerUnit = rule.gramsByUnit[unit], gramsPerUnit > 0 else { return nil }
        return estimateText(value: grams / gramsPerUnit, unit: unit)
    }

    private static func estimateText(value: Double, unit: String) -> String {
        let formatted = value.recipeAmount
        return String(
            format: NSLocalizedString("目安 約%@ %@", comment: "Estimated converted ingredient amount"),
            locale: .current,
            formatted,
            unit
        )
    }
}
