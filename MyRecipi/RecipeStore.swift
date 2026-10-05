import Foundation
import Combine
import UIKit

// レシピの追加・編集・保存をまとめて管理
@MainActor
final class RecipeStore: ObservableObject {
    // ここが変わると画面も更新される
    @Published private(set) var recipes: [Recipe] = []
    @Published private(set) var ingredientHistory: [String] = []
    @Published var professionalData = ProfessionalData()

    private let storageKey = "myrecipi.recipes.v1"
    private let ingredientHistoryKey = "myrecipi.ingredientHistory.v1"
    private let professionalDataKey = "myrecipi.professionalData.v1"

    private static let commonIngredients = [
        "卵", "卵黄", "卵白", "うずら卵", "牛乳", "生クリーム", "無塩バター", "有塩バター", "ヨーグルト",
        "クリームチーズ", "マスカルポーネ", "パルメザンチーズ", "モッツァレラチーズ", "スライスチーズ",
        "薄力粉", "中力粉", "強力粉", "全粒粉", "米粉", "片栗粉", "コーンスターチ", "ベーキングパウダー",
        "ドライイースト", "パン粉", "アーモンドプードル", "ココアパウダー", "粉糖", "グラニュー糖", "上白糖",
        "きび砂糖", "黒糖", "はちみつ", "メープルシロップ", "水あめ", "ゼラチン", "寒天", "チョコレート",
        "ホワイトチョコレート", "バニラビーンズ", "バニラエッセンス", "シナモン", "ラム酒", "ブランデー",
        "鶏もも肉", "鶏むね肉", "鶏ささみ", "手羽先", "手羽元", "鶏ひき肉", "豚バラ肉", "豚ロース肉",
        "豚こま切れ肉", "豚ひき肉", "牛もも肉", "牛バラ肉", "牛こま切れ肉", "牛ひき肉", "合いびき肉",
        "ベーコン", "ハム", "ソーセージ", "ラム肉", "鮭", "たら", "鯛", "さば", "あじ", "ぶり", "まぐろ",
        "かつお", "いわし", "さんま", "えび", "いか", "たこ", "ほたて", "牡蠣", "あさり", "しじみ",
        "木綿豆腐", "絹ごし豆腐", "厚揚げ", "油揚げ", "納豆", "こんにゃく", "しらたき",
        "玉ねぎ", "長ねぎ", "青ねぎ", "にんにく", "しょうが", "にんじん", "大根", "かぶ", "ごぼう", "れんこん",
        "じゃがいも", "さつまいも", "里芋", "山芋", "かぼちゃ", "キャベツ", "白菜", "レタス", "水菜",
        "ほうれん草", "小松菜", "チンゲン菜", "春菊", "にら", "セロリ", "パセリ", "バジル", "ディル",
        "ローズマリー", "タイム", "ミント", "大葉", "きゅうり", "なす", "トマト", "ミニトマト", "ピーマン",
        "パプリカ", "ズッキーニ", "オクラ", "アスパラガス", "ブロッコリー", "カリフラワー", "とうもろこし",
        "たけのこ", "もやし", "枝豆", "さやいんげん", "絹さや", "グリーンピース", "しいたけ", "しめじ",
        "えのき", "まいたけ", "エリンギ", "マッシュルーム", "りんご", "バナナ", "いちご", "みかん", "オレンジ",
        "レモン", "ライム", "キウイ", "桃", "梨", "柿", "ぶどう", "ブルーベリー", "ラズベリー", "マンゴー",
        "パイナップル", "アボカド", "梅干し", "米", "もち米", "玄米", "食パン", "フランスパン", "うどん",
        "そば", "そうめん", "中華麺", "パスタ", "春雨", "オートミール", "コーンフレーク",
        "塩", "こしょう", "しょうゆ", "みそ", "酢", "みりん", "料理酒", "白だし", "めんつゆ", "オイスターソース",
        "ウスターソース", "ケチャップ", "マヨネーズ", "粒マスタード", "豆板醤", "甜麺醤", "コチュジャン",
        "ナンプラー", "オリーブオイル", "ごま油", "サラダ油", "米油", "ラー油", "鶏がらスープの素",
        "コンソメ", "和風だし", "かつお節", "昆布", "白ごま", "黒ごま", "くるみ", "アーモンド", "カシューナッツ"
    ]

    init() {
        load()
        loadProfessionalData()
    }

    // MARK: - レシピの追加・編集・削除

    // 新しいレシピは一覧の先頭に追加
    func add(_ recipe: Recipe) {
        var numberedRecipe = recipe
        if numberedRecipe.recipeNumber == nil || recipes.contains(where: { $0.recipeNumber == numberedRecipe.recipeNumber }) {
            numberedRecipe.recipeNumber = nextRecipeNumber()
        }
        recipes.insert(numberedRecipe, at: 0)
        rememberIngredients(from: numberedRecipe)
        save()
    }

    // 登録済みのレシピを更新
    func update(_ recipe: Recipe) {
        guard let index = recipes.firstIndex(where: { $0.id == recipe.id }) else { return }
        let previous = recipes[index]
        if previous != recipe {
            professionalData.recipeVersions.insert(
                RecipeVersion(label: "編集前", recipe: previous),
                at: 0
            )
            professionalData.recipeVersions = Array(professionalData.recipeVersions.prefix(100))
            saveProfessionalData()
        }
        var numberedRecipe = recipe
        if numberedRecipe.recipeNumber == nil || recipes.contains(where: {
            $0.id != recipe.id && $0.recipeNumber == numberedRecipe.recipeNumber
        }) {
            numberedRecipe.recipeNumber = recipes[index].recipeNumber ?? nextRecipeNumber()
        }
        recipes[index] = numberedRecipe
        rememberIngredients(from: numberedRecipe)
        save()
    }

    // 削除したレシピは30日間残す
    func delete(at offsets: IndexSet, from visibleRecipes: [Recipe]) {
        let ids = offsets.map { visibleRecipes[$0].id }
        let deleted = recipes.filter { ids.contains($0.id) }.map { DeletedRecipe(recipe: $0) }
        professionalData.recentlyDeleted.insert(contentsOf: deleted, at: 0)
        professionalData.recentlyDeleted = professionalData.recentlyDeleted.filter {
            Date().timeIntervalSince($0.deletedAt) < 30 * 24 * 60 * 60
        }
        recipes.removeAll { ids.contains($0.id) }
        saveProfessionalData()
        save()
    }

    func duplicate(_ recipe: Recipe) {
        var copy = recipe
        copy.id = UUID()
        copy.recipeNumber = nil
        copy.title += "（複製）"
        copy.photoFilename = nil
        copy.isFavorite = false
        add(copy)
    }

    func restoreDeleted(_ deleted: DeletedRecipe) {
        guard !recipes.contains(where: { $0.id == deleted.recipe.id }) else { return }
        var restored = deleted.recipe
        if recipes.contains(where: { $0.recipeNumber == restored.recipeNumber }) {
            restored.recipeNumber = nextRecipeNumber()
        }
        recipes.insert(restored, at: 0)
        professionalData.recentlyDeleted.removeAll { $0.id == deleted.id }
        saveProfessionalData()
        save()
    }

    func permanentlyDelete(_ deleted: DeletedRecipe) {
        professionalData.recentlyDeleted.removeAll { $0.id == deleted.id }
        if let filename = deleted.recipe.photoFilename {
            try? FileManager.default.removeItem(at: photoDirectoryURL.appendingPathComponent(filename))
        }
        saveProfessionalData()
    }

    // お気に入りのON・OFFを切り替え
    func toggleFavorite(_ recipe: Recipe) {
        guard let index = recipes.firstIndex(where: { $0.id == recipe.id }) else { return }
        recipes[index].isFavorite.toggle()
        save()
    }

    // MARK: - バックアップと書き出し

    // JSON形式のバックアップを作る
    func backupData() throws -> Data {
        try JSONEncoder.prettyPrinted.encode(
            MyRecipiBackup(recipes: recipes, professionalData: professionalData)
        )
    }

    @discardableResult
    func importBackup(_ data: Data) throws -> Int {
        let decoder = JSONDecoder()
        let archive = try? decoder.decode(MyRecipiBackup.self, from: data)
        let imported = try archive?.recipes ?? decoder.decode([Recipe].self, from: data)
        for recipe in imported {
            if let index = recipes.firstIndex(where: { $0.id == recipe.id }) {
                recipes[index] = recipe
            } else {
                recipes.append(recipe)
            }
        }
        normalizeRecipeNumbers()
        imported.forEach { rememberIngredients(from: $0) }
        if let archive {
            professionalData = archive.professionalData
            saveProfessionalData()
        }
        save()
        return imported.count
    }

    func csvData() -> Data {
        var rows = ["レシピ番号,料理名,カテゴリ,食材,分量,単位,用途"]
        for recipe in recipes {
            for ingredient in recipe.ingredients {
                rows.append([
                    recipe.recipeNumberText, recipe.title, recipe.category, ingredient.name,
                    ingredient.amount.recipeAmount, ingredient.unit, ingredient.group ?? ""
                ].map(csvEscaped).joined(separator: ","))
            }
        }
        return rows.joined(separator: "\n").data(using: .utf8) ?? Data()
    }

    // MARK: - 原価・調理記録

    func profile(for ingredientName: String) -> IngredientProfile? {
        let key = normalizeIngredientName(ingredientName)
        return professionalData.ingredientProfiles.first { normalizeIngredientName($0.name) == key }
    }

    func saveProfile(_ profile: IngredientProfile) {
        let key = normalizeIngredientName(profile.name)
        if let index = professionalData.ingredientProfiles.firstIndex(where: {
            normalizeIngredientName($0.name) == key
        }) {
            professionalData.ingredientProfiles[index] = profile
        } else {
            professionalData.ingredientProfiles.append(profile)
        }
        saveProfessionalData()
    }

    func cost(of ingredient: Ingredient, scale: Double = 1) -> Double? {
        guard let profile = profile(for: ingredient.name), profile.packagePrice > 0, profile.packageAmount > 0 else { return nil }
        let recipeAmount = KitchenKnowledge.normalizedAmount(ingredient.amount * scale, unit: ingredient.unit)
        let packageAmount = KitchenKnowledge.normalizedAmount(profile.packageAmount, unit: profile.packageUnit)
        guard recipeAmount.1.caseInsensitiveCompare(packageAmount.1) == .orderedSame else { return nil }
        return recipeAmount.0 / packageAmount.0 * profile.packagePrice / profile.usableRatio
    }

    func totalCost(for recipe: Recipe, scale: Double = 1) -> Double {
        recipe.ingredients.compactMap { cost(of: $0, scale: scale) }.reduce(0, +)
    }

    func addCookingRecord(_ record: CookingRecord) {
        professionalData.cookingRecords.insert(record, at: 0)
        saveProfessionalData()
    }

    func addCookingRecord(_ source: CookingRecord, photoData: Data?) {
        var record = source
        if let photoData, let image = UIImage(data: photoData), let jpeg = image.jpegData(compressionQuality: 0.8) {
            try? FileManager.default.createDirectory(at: photoDirectoryURL, withIntermediateDirectories: true)
            let filename = "record-\(record.id.uuidString).jpg"
            try? jpeg.write(to: photoDirectoryURL.appendingPathComponent(filename), options: .atomic)
            record.photoFilename = filename
        }
        addCookingRecord(record)
    }

    func cookingRecordPhoto(_ record: CookingRecord) -> UIImage? {
        guard let filename = record.photoFilename,
              let data = try? Data(contentsOf: photoDirectoryURL.appendingPathComponent(filename)) else { return nil }
        return UIImage(data: data)
    }

    func records(for recipeID: UUID) -> [CookingRecord] {
        professionalData.cookingRecords.filter { $0.recipeID == recipeID }.sorted { $0.createdAt > $1.createdAt }
    }

    func versions(for recipeID: UUID) -> [RecipeVersion] {
        professionalData.recipeVersions.filter { $0.recipe.id == recipeID }.sorted { $0.savedAt > $1.savedAt }
    }

    func restoreVersion(_ version: RecipeVersion) {
        update(version.recipe)
    }

    // MARK: - 買い物リストと仕込みリスト

    func setShoppingSelection(_ recipeID: UUID, selected: Bool) {
        if selected { professionalData.shoppingRecipeIDs.insert(recipeID) }
        else { professionalData.shoppingRecipeIDs.remove(recipeID) }
        saveProfessionalData()
    }

    var shoppingItems: [ShoppingItem] {
        let selected = recipes.filter { professionalData.shoppingRecipeIDs.contains($0.id) }
        var buckets: [String: (name: String, amount: Double, unit: String, titles: Set<String>)] = [:]
        for recipe in selected {
            for ingredient in recipe.ingredients where ingredient.unit != "分量外" {
                let normalized = KitchenKnowledge.normalizedAmount(ingredient.amount, unit: ingredient.unit)
                let key = "\(normalizeIngredientName(ingredient.name))|\(normalized.1.lowercased())"
                var value = buckets[key] ?? (ingredient.name, 0, normalized.1, [])
                value.amount += normalized.0
                value.titles.insert(recipe.title)
                buckets[key] = value
            }
        }
        return buckets.map { key, value in
            ShoppingItem(key: key, name: value.name, amount: value.amount, unit: value.unit, recipeTitles: value.titles.sorted())
        }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    func toggleShoppingItem(_ key: String) {
        if professionalData.checkedShoppingKeys.contains(key) { professionalData.checkedShoppingKeys.remove(key) }
        else { professionalData.checkedShoppingKeys.insert(key) }
        saveProfessionalData()
    }

    func togglePrepItem(_ key: String) {
        if professionalData.checkedPrepKeys.contains(key) { professionalData.checkedPrepKeys.remove(key) }
        else { professionalData.checkedPrepKeys.insert(key) }
        saveProfessionalData()
    }

    func saveStepPhoto(_ data: Data, recipeID: UUID, stepIndex: Int) {
        guard let image = UIImage(data: data), let jpeg = image.jpegData(compressionQuality: 0.8) else { return }
        do {
            try FileManager.default.createDirectory(at: photoDirectoryURL, withIntermediateDirectories: true)
            let key = "\(recipeID.uuidString)-\(stepIndex)"
            let filename = "step-\(key).jpg"
            try jpeg.write(to: photoDirectoryURL.appendingPathComponent(filename), options: .atomic)
            professionalData.stepPhotoFilenames[key] = filename
            saveProfessionalData()
        } catch { return }
    }

    func stepPhoto(recipeID: UUID, stepIndex: Int) -> UIImage? {
        let key = "\(recipeID.uuidString)-\(stepIndex)"
        guard let filename = professionalData.stepPhotoFilenames[key],
              let data = try? Data(contentsOf: photoDirectoryURL.appendingPathComponent(filename)) else { return nil }
        return UIImage(data: data)
    }

    // MARK: - 端末への保存と読み込み

    // 端末に保存したレシピを読み込む
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([Recipe].self, from: data) else {
            recipes = [.sample]
            loadIngredientHistory(fallbackRecipes: recipes)
            return
        }
        recipes = decoded
        normalizeRecipeNumbers()
        loadIngredientHistory(fallbackRecipes: recipes)
        save()
    }

    // 現在のレシピを端末に保存
    private func save() {
        guard let data = try? JSONEncoder().encode(recipes) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
        let completeBackup = try? JSONEncoder.prettyPrinted.encode(
            MyRecipiBackup(recipes: recipes, professionalData: professionalData)
        )
        saveAutomaticBackup(completeBackup ?? data)
    }

    private func loadProfessionalData() {
        guard let data = UserDefaults.standard.data(forKey: professionalDataKey),
              let decoded = try? JSONDecoder().decode(ProfessionalData.self, from: data) else { return }
        professionalData = decoded
    }

    func saveProfessionalData() {
        guard let data = try? JSONEncoder().encode(professionalData) else { return }
        UserDefaults.standard.set(data, forKey: professionalDataKey)
    }

    private func saveAutomaticBackup(_ data: Data) {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("MyRecipiAutoBackups", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        let formatter = ISO8601DateFormatter()
        let filename = formatter.string(from: Date()).replacingOccurrences(of: ":", with: "-") + ".json"
        try? data.write(to: base.appendingPathComponent(filename), options: .atomic)
        let files = ((try? FileManager.default.contentsOfDirectory(at: base, includingPropertiesForKeys: [.contentModificationDateKey])) ?? [])
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
        for file in files.dropFirst(5) { try? FileManager.default.removeItem(at: file) }
    }

    private func csvEscaped(_ value: String) -> String {
        "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    // MARK: - 材料名の予測候補

    // 入力中の文字に合う材料を候補に出す
    func ingredientSuggestions(matching query: String, limit: Int = 12) -> [String] {
        let normalizedQuery = normalizeIngredientName(query)
        let bilingualIngredients = FrenchCulinaryGlossary.terms
            .filter { $0.category == "食材" }
            .flatMap {
                [$0.french, $0.reading, FrenchCulinaryGlossary.primaryJapaneseName(for: $0)]
            }
        var seen = Set<String>()
        let candidates = (ingredientHistory + Self.commonIngredients + bilingualIngredients).filter {
            let normalized = normalizeIngredientName($0)
            let matches = normalizedQuery.isEmpty || normalized.contains(normalizedQuery)
            return matches && seen.insert(normalized).inserted
        }
        return Array(candidates.prefix(limit))
    }

    // MARK: - 写真

    func saveFinishedPhoto(_ data: Data, for recipeID: UUID) {
        guard let index = recipes.firstIndex(where: { $0.id == recipeID }),
              let image = UIImage(data: data),
              let jpeg = image.jpegData(compressionQuality: 0.82) else { return }
        do {
            try FileManager.default.createDirectory(at: photoDirectoryURL, withIntermediateDirectories: true)
            let filename = "\(recipeID.uuidString).jpg"
            try jpeg.write(to: photoDirectoryURL.appendingPathComponent(filename), options: .atomic)
            recipes[index].photoFilename = filename
            save()
        } catch {
            return
        }
    }

    func photoImage(for recipe: Recipe) -> UIImage? {
        guard let filename = recipe.photoFilename,
              let data = try? Data(contentsOf: photoDirectoryURL.appendingPathComponent(filename)) else { return nil }
        return UIImage(data: data)
    }

    private var photoDirectoryURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("MyRecipiPhotos", isDirectory: true)
    }

    private func loadIngredientHistory(fallbackRecipes: [Recipe]) {
        if let saved = UserDefaults.standard.stringArray(forKey: ingredientHistoryKey), !saved.isEmpty {
            ingredientHistory = saved
            return
        }
        for recipe in fallbackRecipes.reversed() {
            rememberIngredients(from: recipe)
        }
    }

    private func rememberIngredients(from recipe: Recipe) {
        var updated = ingredientHistory
        for ingredient in recipe.ingredients.reversed() {
            let name = ingredient.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { continue }
            let normalized = normalizeIngredientName(name)
            updated.removeAll { normalizeIngredientName($0) == normalized }
            updated.insert(name, at: 0)
        }
        ingredientHistory = Array(updated.prefix(300))
        UserDefaults.standard.set(ingredientHistory, forKey: ingredientHistoryKey)
    }

    private func normalizeIngredientName(_ name: String) -> String {
        name.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: .current)
            .replacingOccurrences(of: #"[\s・\-_]"#, with: "", options: .regularExpression)
    }

    // MARK: - レシピ番号

    // 次に使えるレシピ番号
    private func nextRecipeNumber() -> Int {
        (recipes.compactMap(\.recipeNumber).max() ?? 0) + 1
    }

    private func normalizeRecipeNumbers() {
        var used = Set<Int>()
        var next = (recipes.compactMap(\.recipeNumber).filter { $0 > 0 }.max() ?? 0) + 1
        for index in recipes.indices {
            if let number = recipes[index].recipeNumber, number > 0, used.insert(number).inserted {
                continue
            }
            while used.contains(next) { next += 1 }
            recipes[index].recipeNumber = next
            used.insert(next)
            next += 1
        }
    }
}

private extension JSONEncoder {
    static var prettyPrinted: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}
