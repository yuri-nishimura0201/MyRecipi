import SwiftUI
import PhotosUI
import UIKit

// レシピ関係の画面を上から順番にまとめたファイル
// 1. RecipeLibraryView   : レシピ一覧
// 2. FavoritesView       : お気に入り
// 3. IngredientSearchView: 食材から検索
// 4. RecipeDetailView    : レシピ詳細
// 5. RecipeEditorView    : レシピ入力・編集

// MARK: - 1. レシピ一覧画面

struct RecipeLibraryView: View {
    @ObservedObject var store: RecipeStore
    @State private var searchText = ""
    @State private var selectedCategory = "すべて"
    @State private var showingEditor = false
    @State private var scanItems: [PhotosPickerItem] = []
    @State private var scannedRecipe: Recipe?
    @State private var scannedSourcePhoto: UIImage?
    @State private var isScanning = false
    @State private var scanError = false
    @State private var showingCamera = false
    @State private var cameraUnavailable = false

    private var categories: [String] {
        let custom = Set(store.recipes.map(\.category).filter {
            !$0.isEmpty && !Recipe.standardCategories.contains($0)
        })
        return ["すべて"] + Recipe.standardCategories + custom.sorted()
    }

    private var filteredRecipes: [Recipe] {
        store.recipes.filter { recipe in
            let matchesCategory = selectedCategory == "すべて" || recipe.category == selectedCategory
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let matchesSearch = query.isEmpty || recipe.title.localizedCaseInsensitiveContains(query) ||
                recipe.ingredients.contains { $0.name.localizedCaseInsensitiveContains(query) } ||
                recipe.recipeNumber.map { String($0) == query || recipe.recipeNumberText.localizedCaseInsensitiveContains(query) } == true
            return matchesCategory && matchesSearch
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if categories.count > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(categories, id: \.self) { category in
                                Button(localizedCategory(category)) { selectedCategory = category }
                                    .buttonStyle(.bordered)
                                    .tint(selectedCategory == category ? .orange : .secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .listRowSeparator(.hidden)
                }

                if filteredRecipes.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty ? "レシピがありません" : "見つかりませんでした",
                        systemImage: "fork.knife",
                        description: Text(searchText.isEmpty ? "右上の＋から最初のレシピを登録しましょう。" : "料理名や食材名を変えて検索してください。")
                    )
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(filteredRecipes) { recipe in
                        NavigationLink {
                            RecipeDetailView(store: store, recipeID: recipe.id)
                        } label: {
                            RecipeRow(recipe: recipe)
                        }
                        .swipeActions(edge: .leading) {
                            Button { store.toggleFavorite(recipe) } label: {
                                Label(recipe.isFavorite ? "解除" : "お気に入り", systemImage: recipe.isFavorite ? "heart.slash" : "heart")
                            }
                            .tint(.pink)
                        }
                    }
                    .onDelete { store.delete(at: $0, from: filteredRecipes) }
                }
            }
            .listStyle(.plain)
            .navigationTitle("My Recipi")
            .searchable(text: $searchText, prompt: "料理名・食材名で検索")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            showingCamera = true
                        } else {
                            cameraUnavailable = true
                        }
                    } label: {
                        Label("カメラで撮影", systemImage: "camera")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    PhotosPicker(selection: $scanItems, maxSelectionCount: 10, matching: .images) {
                        if isScanning {
                            ProgressView()
                        } else {
                            Label("写真から追加", systemImage: "doc.viewfinder")
                        }
                    }
                    .disabled(isScanning)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingEditor = true } label: {
                        Label("レシピを追加", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingEditor) {
                RecipeEditorView(store: store) { store.add($0) }
            }
            .sheet(item: $scannedRecipe) { draft in
                RecipeEditorView(store: store, recipe: draft, sourcePhoto: scannedSourcePhoto) { store.add($0) }
            }
            .fullScreenCover(isPresented: $showingCamera) {
                CameraPicker { data in
                    scanImageData(data)
                }
                .ignoresSafeArea()
            }
            .alert("読み取れませんでした", isPresented: $scanError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("明るい場所で、紙全体が入るように撮影した写真をお試しください。")
            }
            .alert("カメラを使用できません", isPresented: $cameraUnavailable) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("シミュレーターではカメラを使用できません。写真から追加をお使いください。")
            }
            .onChange(of: scanItems) { _, items in
                guard !items.isEmpty else { return }
                scanFromLibrary(items)
            }
        }
    }

    private func scanFromLibrary(_ items: [PhotosPickerItem]) {
        isScanning = true
        Task {
            do {
                var pages: [Data] = []
                for item in items {
                    if let data = try await item.loadTransferable(type: Data.self) { pages.append(data) }
                }
                guard !pages.isEmpty else { throw RecipeOCRError.imageUnavailable }
                try await applyScannedDraft(from: pages)
            } catch {
                scanError = true
            }
            isScanning = false
            scanItems = []
        }
    }

    private func scanImageData(_ data: Data) {
        isScanning = true
        Task {
            do {
                try await applyScannedDraft(from: [data])
            } catch {
                scanError = true
            }
            isScanning = false
        }
    }

    private func applyScannedDraft(from pages: [Data]) async throws {
        let draft = try await RecipeOCRService.makeDraft(from: pages)
        scannedSourcePhoto = pages.first.flatMap(UIImage.init(data:))
        scannedRecipe = Recipe(
            title: draft.title,
            category: "和食",
            servings: 2,
            cookingMinutes: 30,
            ingredients: draft.ingredients.isEmpty ? [Ingredient(name: "", amount: 0, unit: "g")] : draft.ingredients,
            steps: draft.steps.isEmpty ? [""] : draft.steps,
            notes: draft.needsReview ? "⚠️ 写真読み取りで確信度の低い文字があります。原本と照合してください。" : "",
            isFavorite: false
        )
    }
}

// MARK: - 2. お気に入り画面

struct FavoritesView: View {
    @ObservedObject var store: RecipeStore

    private var favorites: [Recipe] { store.recipes.filter(\.isFavorite) }

    var body: some View {
        NavigationStack {
            Group {
                if favorites.isEmpty {
                    ContentUnavailableView("お気に入りはまだありません", systemImage: "heart", description: Text("よく作るレシピをハートでまとめられます。"))
                } else {
                    List(favorites) { recipe in
                        NavigationLink {
                            RecipeDetailView(store: store, recipeID: recipe.id)
                        } label: {
                            RecipeRow(recipe: recipe)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("お気に入り")
        }
    }
}

// 一覧に表示するレシピ1行分
private struct RecipeRow: View {
    let recipe: Recipe

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14).fill(Color.orange.opacity(0.13))
                Image(systemName: "fork.knife").font(.title2.weight(.semibold)).foregroundStyle(.orange)
            }
            .frame(width: 58, height: 58)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(recipe.title).font(.headline)
                    if recipe.isFavorite { Image(systemName: "heart.fill").foregroundStyle(.pink).font(.caption) }
                }
                HStack(spacing: 12) {
                    Text(recipe.recipeNumberText)
                    Label(recipe.yieldDescription, systemImage: recipe.baseYieldUnit == "人分" ? "person.2" : "scalemass")
                    Label("\(recipe.cookingMinutes)分", systemImage: "clock")
                    if !recipe.category.isEmpty { Text(localizedCategory(recipe.category)) }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - 3. 食材から検索する画面

struct IngredientSearchView: View {
    @ObservedObject var store: RecipeStore
    @State private var query = ""
    @State private var matchAll = true
    @FocusState private var searchFieldFocused: Bool

    private struct Match: Identifiable {
        let recipe: Recipe
        let matchedTerms: [String]
        var id: UUID { recipe.id }
    }

    private var terms: [String] {
        var seen = Set<String>()
        return query
            .components(separatedBy: CharacterSet(charactersIn: "、,，\n\t"))
            .flatMap { $0.split(separator: " ").map(String.init) }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && seen.insert(normalize($0)).inserted }
    }

    private var matches: [Match] {
        guard !terms.isEmpty else { return [] }
        return store.recipes.compactMap { recipe in
            let matched = terms.filter { term in
                recipe.ingredients.contains { ingredientMatches($0.name, term: term) }
            }
            guard matchAll ? matched.count == terms.count : !matched.isEmpty else { return nil }
            return Match(recipe: recipe, matchedTerms: matched)
        }
        .sorted {
            if $0.matchedTerms.count != $1.matchedTerms.count {
                return $0.matchedTerms.count > $1.matchedTerms.count
            }
            return $0.recipe.title.localizedCompare($1.recipe.title) == .orderedAscending
        }
    }

    private var popularIngredients: [String] {
        var counts: [String: (display: String, count: Int)] = [:]
        for ingredient in store.recipes.flatMap(\.ingredients) {
            let display = ingredient.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !display.isEmpty else { continue }
            let key = normalize(display)
            counts[key] = (counts[key]?.display ?? display, (counts[key]?.count ?? 0) + 1)
        }
        return counts.values
            .sorted { $0.count == $1.count ? $0.display < $1.display : $0.count > $1.count }
            .prefix(12)
            .map(\.display)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("食材を「、」で区切って入力", text: $query, axis: .vertical)
                        .lineLimit(1...3)
                        .textInputAutocapitalization(.never)
                        .focused($searchFieldFocused)
                        .submitLabel(.search)
                        .onSubmit { searchFieldFocused = false }

                    Picker("検索条件", selection: $matchAll) {
                        Text("すべて含む").tag(true)
                        Text("いずれか含む").tag(false)
                    }
                    .pickerStyle(.segmented)
                } footer: {
                    Text("例：鶏肉、玉ねぎ。入力した食材を使うレシピを一致数順で表示します。")
                }

                if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Section("よく使う食材") {
                        if popularIngredients.isEmpty {
                            Text("レシピを登録すると、よく使う食材がここに表示されます。")
                                .foregroundStyle(.secondary)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(popularIngredients, id: \.self) { ingredient in
                                        Button(ingredient) {
                                            addTerm(ingredient)
                                            searchFieldFocused = false
                                        }
                                            .buttonStyle(.bordered)
                                            .tint(.orange)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                            .listRowSeparator(.hidden)
                        }
                    }
                } else if matches.isEmpty {
                    ContentUnavailableView(
                        "条件に合うレシピがありません",
                        systemImage: "carrot",
                        description: Text("食材を減らすか、「いずれか含む」に切り替えてください。")
                    )
                    .listRowSeparator(.hidden)
                } else {
                    Section("検索結果") {
                        ForEach(matches) { match in
                            NavigationLink {
                                RecipeDetailView(store: store, recipeID: match.recipe.id)
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    RecipeRow(recipe: match.recipe)
                                    Text(String(
                                        format: NSLocalizedString("一致：%@", comment: "Matched ingredient terms"),
                                        match.matchedTerms.joined(separator: "、")
                                    ))
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                                }
                            }
                        }
                    }
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle("食材から探す")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完了") {
                        searchFieldFocused = false
                        dismissKeyboard()
                    }
                }
            }
        }
    }

    private func addTerm(_ ingredient: String) {
        let current = terms
        guard !current.contains(where: { normalize($0) == normalize(ingredient) }) else { return }
        query = (current + [ingredient]).joined(separator: "、")
    }

    private func normalize(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: .current)
            .replacingOccurrences(of: #"[\s・\-_]"#, with: "", options: .regularExpression)
    }

    private func ingredientMatches(_ ingredient: String, term: String) -> Bool {
        let ingredientText = normalize(ingredient)
        let termText = normalize(term)
        if ingredientText.contains(termText) || termText.contains(ingredientText) { return true }

        let groups = [
            ["鶏肉", "鶏もも肉", "鶏むね肉", "鶏胸肉", "チキン"],
            ["豚肉", "豚バラ肉", "豚こま肉", "豚ひき肉", "ポーク"],
            ["牛肉", "牛こま肉", "牛ひき肉", "ビーフ"],
            ["卵", "たまご", "玉子"],
            ["玉ねぎ", "たまねぎ", "タマネギ"],
            ["じゃがいも", "ジャガイモ", "馬鈴薯"],
            ["にんじん", "人参", "ニンジン"]
        ]
        return groups.contains { group in
            let normalizedGroup = group.map(normalize)
            return normalizedGroup.contains(termText) && normalizedGroup.contains(ingredientText)
        }
    }
}

// MARK: - 4. レシピ詳細画面

struct RecipeDetailView: View {
    private struct IngredientDisplayGroup: Identifiable {
        let id: Int
        let name: String?
        let ingredients: [Ingredient]
    }

    @ObservedObject var store: RecipeStore
    let recipeID: UUID
    @State private var targetYield = 1.0
    @State private var baseIngredientID: UUID?
    @State private var baseAmount = ""
    @State private var checkedSteps: Set<Int> = []
    @State private var showingEditor = false
    @State private var ingredientNameLanguage = "登録名"

    private var recipe: Recipe? { store.recipes.first { $0.id == recipeID } }

    private var scale: Double {
        guard let recipe else { return 1 }
        if let id = baseIngredientID,
           let ingredient = recipe.ingredients.first(where: { $0.id == id }),
           let amount = Double(baseAmount.replacingOccurrences(of: ",", with: ".")), ingredient.amount > 0 {
            return amount / ingredient.amount
        }
        return recipe.scale(for: targetYield)
    }

    private func groupedIngredients(_ ingredients: [Ingredient]) -> [IngredientDisplayGroup] {
        var groups: [(name: String?, ingredients: [Ingredient])] = []
        for ingredient in ingredients {
            let trimmed = ingredient.group?.trimmingCharacters(in: .whitespacesAndNewlines)
            let groupName = (trimmed?.isEmpty == false) ? trimmed : nil
            if let last = groups.indices.last, groups[last].name == groupName {
                groups[last].ingredients.append(ingredient)
            } else {
                groups.append((groupName, [ingredient]))
            }
        }
        return groups.enumerated().map {
            IngredientDisplayGroup(id: $0.offset, name: $0.element.name, ingredients: $0.element.ingredients)
        }
    }

    var body: some View {
        Group {
            if let recipe {
                List {
                    Section {
                        if let photo = store.photoImage(for: recipe) {
                            Image(uiImage: photo)
                                .resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .accessibilityLabel("完成写真")
                        }
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(recipe.category.isEmpty ? NSLocalizedString("レシピ", comment: "") : localizedCategory(recipe.category))
                                    .font(.caption.weight(.semibold)).foregroundStyle(.orange)
                                Text(recipe.title).font(.title2.bold())
                                Text(recipe.recipeNumberText)
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button { store.toggleFavorite(recipe) } label: {
                                Image(systemName: recipe.isFavorite ? "heart.fill" : "heart")
                                    .font(.title2).foregroundStyle(.pink)
                            }
                            .buttonStyle(.plain)
                        }
                        Label("調理時間の目安  \(recipe.cookingMinutes)分", systemImage: "clock")
                            .foregroundStyle(.secondary)
                        if let temperature = recipe.preheatTemperature {
                            Label("予熱  \(temperature)℃", systemImage: "oven")
                                .font(.headline)
                                .foregroundStyle(.orange)
                        }
                    }

                    Section("分量を計算") {
                        Stepper(value: $targetYield, in: 0.25...500, step: yieldStep(for: recipe)) {
                            Text(recipe.yieldDescription(for: targetYield))
                        }
                            .onChange(of: targetYield) { _, _ in
                                baseIngredientID = nil
                                baseAmount = ""
                            }
                        Menu {
                            Button(String(
                                format: NSLocalizedString("%@を基準にする", comment: "Use yield as calculation basis"),
                                localizedYieldUnit(recipe.baseYieldUnit)
                            )) {
                                baseIngredientID = nil
                                baseAmount = ""
                            }
                            ForEach(recipe.ingredients) { ingredient in
                                Button(ingredient.name) {
                                    baseIngredientID = ingredient.id
                                    baseAmount = (ingredient.amount * recipe.scale(for: targetYield)).recipeAmount
                                }
                            }
                        } label: {
                            HStack {
                                Label("計算の基準", systemImage: "scalemass")
                                Spacer()
                                Text(recipe.ingredients.first(where: { $0.id == baseIngredientID })?.name ?? localizedYieldUnit(recipe.baseYieldUnit))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        if let id = baseIngredientID, let ingredient = recipe.ingredients.first(where: { $0.id == id }) {
                            HStack {
                                Text(ingredient.name)
                                Spacer()
                                TextField("分量", text: $baseAmount)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(maxWidth: 90)
                                Text(ingredient.unit).foregroundStyle(.secondary)
                            }
                        }
                        if ["号", "直径cm"].contains(recipe.baseYieldUnit) {
                            Text("ケーキの号数・直径は、型の面積に合わせて材料を換算します。")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Section {
                        Picker("食材名表示", selection: $ingredientNameLanguage) {
                            Text("登録名").tag("登録名")
                            Text("日本語").tag("日本語")
                            Text("Français").tag("Français")
                        }
                        .pickerStyle(.segmented)

                        ForEach(groupedIngredients(recipe.ingredients)) { group in
                            if let groupName = group.name {
                                Text(groupName)
                                    .font(.headline)
                                    .foregroundStyle(.orange)
                                    .padding(.top, 4)
                            }
                            ForEach(group.ingredients) { ingredient in
                                let calculatedAmount = ingredient.amount * scale
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack {
                                        Text(FrenchCulinaryGlossary.translatedIngredientName(
                                            ingredient.name,
                                            language: ingredientNameLanguage
                                        ))
                                        Spacer()
                                        Text(ingredient.amountDescription(scale: scale))
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.orange)
                                    }
                                    if let estimate = IngredientConversion.estimate(for: ingredient, amount: calculatedAmount) {
                                        Text(estimate)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .frame(maxWidth: .infinity, alignment: .trailing)
                                    }
                                }
                            }
                        }
                    } header: {
                        Text("材料")
                    }

                    Section("作り方") {
                        ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top, spacing: 12) {
                                Button {
                                    if checkedSteps.contains(index) { checkedSteps.remove(index) }
                                    else { checkedSteps.insert(index) }
                                } label: {
                                    ZStack {
                                        Circle().fill(checkedSteps.contains(index) ? Color.green : Color.orange)
                                        if checkedSteps.contains(index) {
                                            Image(systemName: "checkmark").font(.caption.bold()).foregroundStyle(.white)
                                        } else {
                                            Text("\(index + 1)").font(.caption.bold()).foregroundStyle(.white)
                                        }
                                    }
                                    .frame(width: 28, height: 28)
                                }
                                .buttonStyle(.plain)

                                VStack(alignment: .leading, spacing: 8) {
                                    Text(stepWithIngredientAmounts(step, recipe: recipe, scale: scale))
                                        .foregroundStyle(checkedSteps.contains(index) ? .secondary : .primary)
                                        .strikethrough(checkedSteps.contains(index))
                                        .multilineTextAlignment(.leading)

                                    ForEach(linkedRecipes(in: step)) { linkedRecipe in
                                        NavigationLink {
                                            RecipeDetailView(store: store, recipeID: linkedRecipe.id)
                                        } label: {
                                            Label(
                                                String(
                                                    format: NSLocalizedString("%@  %@を開く", comment: "Open referenced recipe"),
                                                    linkedRecipe.recipeNumberText,
                                                    linkedRecipe.title
                                                ),
                                                systemImage: "arrow.turn.down.right"
                                            )
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.orange)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }

                    if !recipe.notes.isEmpty {
                        Section("メモ") { Text(recipe.notes) }
                    }

                    Section {
                        NavigationLink {
                            RecipeProfessionalView(store: store, recipe: recipe)
                        } label: {
                            Label("原価・タイマー・記録・PDF", systemImage: "wrench.and.screwdriver")
                                .foregroundStyle(.orange)
                        }
                    } header: {
                        Text("専門ツール")
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("編集") { showingEditor = true }
                    }
                }
                .sheet(isPresented: $showingEditor) {
                    RecipeEditorView(store: store, recipe: recipe) { store.update($0) }
                }
                .onAppear { targetYield = recipe.baseYieldAmount }
            }
        }
    }

    private func yieldStep(for recipe: Recipe) -> Double {
        switch recipe.baseYieldUnit {
        case "号", "直径cm": return 0.5
        default: return 0.25
        }
    }

    private func stepWithIngredientAmounts(_ step: String, recipe: Recipe, scale: Double) -> String {
        let ingredients = recipe.ingredients.filter {
            !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && $0.amount > 0
        }
        guard !ingredients.isEmpty else { return step }

        var ingredientByAlias: [String: Ingredient] = [:]
        for ingredient in ingredients {
            for alias in FrenchCulinaryGlossary.equivalentIngredientNames(for: ingredient.name) {
                if ingredientByAlias[alias] == nil { ingredientByAlias[alias] = ingredient }
            }
        }
        let aliases = ingredientByAlias.keys.sorted { $0.count > $1.count }
        let pattern = aliases.map { alias in
            let escaped = NSRegularExpression.escapedPattern(for: alias)
            let containsLatin = alias.range(of: #"[A-Za-zÀ-ÿœŒ]"#, options: .regularExpression) != nil
            return containsLatin ? #"(?<![A-Za-zÀ-ÿœŒ])"# + escaped + #"(?![A-Za-zÀ-ÿœŒ])"# : escaped
        }.joined(separator: "|")
        guard !pattern.isEmpty,
              let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return step }

        let mutable = NSMutableString(string: step)
        let original = step as NSString
        let matches = regex.matches(in: step, range: NSRange(step.startIndex..., in: step))
        for match in matches.reversed() {
            let suffixLocation = NSMaxRange(match.range)
            let suffix = suffixLocation < original.length ? original.substring(from: suffixLocation) : ""
            let trimmedSuffix = suffix.trimmingCharacters(in: .whitespaces)
            if trimmedSuffix.hasPrefix("（分量外）") || trimmedSuffix.hasPrefix("(分量外)") { continue }
            let name = original.substring(with: match.range)
            guard let ingredient = ingredientByAlias.first(where: {
                $0.key.compare(name, options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive]) == .orderedSame
            })?.value else { continue }
            let replacement = "\(name)（\(ingredient.amountDescription(scale: scale))）"
            mutable.replaceCharacters(in: match.range, with: replacement)
        }
        return mutable as String
    }

    private func linkedRecipes(in step: String) -> [Recipe] {
        guard let regex = try? NSRegularExpression(
            pattern: #"(?:レシピ\s*(?:番号)?|No\.?|#)\s*([0-9]+)"#,
            options: [.caseInsensitive]
        ) else { return [] }

        var numbers: [Int] = []
        let matches = regex.matches(in: step, range: NSRange(step.startIndex..., in: step))
        for match in matches {
            guard match.numberOfRanges > 1,
                  let range = Range(match.range(at: 1), in: step),
                  let number = Int(step[range]),
                  !numbers.contains(number) else { continue }
            numbers.append(number)
        }
        return numbers.compactMap { number in
            store.recipes.first { $0.recipeNumber == number }
        }
    }

}

// 音声入力を材料と工程のどちらに入れるか
private enum VoiceInputTarget: Equatable {
    case ingredient(UUID)
    case step(Int)
}

// 写真読み取り後に、元の紙レシピを大きく確認する画面
private struct SourceRecipePhotoView: View {
    @Environment(\.dismiss) private var dismiss
    let image: UIImage

    var body: some View {
        NavigationStack {
            ScrollView {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .background(Color.black.opacity(0.94))
            .navigationTitle("元のレシピ写真")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }
}

// MARK: - 5. レシピ入力・編集画面

struct RecipeEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: RecipeStore
    @State private var recipe: Recipe
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var sourcePhotoPreview: UIImage?
    @State private var showingSourcePhoto = false
    @State private var selectedFinishedPhoto: PhotosPickerItem?
    @State private var finishedPhotoData: Data?
    @State private var finishedPhotoPreview: UIImage?
    @State private var isReadingPhoto = false
    @State private var readingMessage = ""
    @State private var cookingTermStepIndex: Int?
    @State private var showingCookingTermPicker = false
    @StateObject private var voiceInput = VoiceInputManager()
    @State private var voiceInputTarget: VoiceInputTarget?
    @FocusState private var focusedIngredientID: UUID?
    @FocusState private var focusedStepIndex: Int?
    let onSave: (Recipe) -> Void

    init(
        store: RecipeStore,
        recipe: Recipe? = nil,
        sourcePhoto: UIImage? = nil,
        onSave: @escaping (Recipe) -> Void
    ) {
        self.store = store
        _recipe = State(initialValue: recipe ?? Recipe(title: "", category: "和食", servings: 2, cookingMinutes: 30, ingredients: [Ingredient(name: "", amount: 0, unit: "g")], steps: [""], notes: "", isFavorite: false))
        _sourcePhotoPreview = State(initialValue: sourcePhoto)
        _finishedPhotoPreview = State(initialValue: recipe.flatMap { store.photoImage(for: $0) })
        self.onSave = onSave
    }

    private var canSave: Bool {
        !recipe.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        recipe.ingredients.contains { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } &&
        recipe.steps.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    private var yieldAmountBinding: Binding<Double> {
        Binding(
            get: { recipe.yieldAmount ?? Double(recipe.servings) },
            set: { newValue in
                recipe.yieldAmount = max(newValue, 0.01)
                if recipe.baseYieldUnit == "人分" {
                    recipe.servings = max(1, Int(newValue.rounded()))
                }
            }
        )
    }

    private var yieldUnitBinding: Binding<String> {
        Binding(
            get: { recipe.yieldUnit ?? "人分" },
            set: { recipe.yieldUnit = $0 }
        )
    }

    private var preheatEnabledBinding: Binding<Bool> {
        Binding(
            get: { recipe.preheatTemperature != nil },
            set: { enabled in recipe.preheatTemperature = enabled ? (recipe.preheatTemperature ?? 180) : nil }
        )
    }

    private var preheatTemperatureBinding: Binding<Int> {
        Binding(
            get: { recipe.preheatTemperature ?? 180 },
            set: { recipe.preheatTemperature = $0 }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if let sourcePhotoPreview {
                        Button {
                            dismissKeyboard()
                            showingSourcePhoto = true
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Image(uiImage: sourcePhotoPreview)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: .infinity, maxHeight: 260)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))

                                Label("元の写真を拡大して確認", systemImage: "arrow.up.left.and.arrow.down.right")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(.orange)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("読み取った元の写真を拡大して確認")
                    }

                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        HStack {
                            Label(
                                isReadingPhoto
                                    ? "写真を読み取り中…"
                                    : (sourcePhotoPreview == nil ? "紙のレシピを写真から読み取る" : "別の写真に変更して読み取る"),
                                systemImage: "doc.viewfinder"
                            )
                            Spacer()
                            if isReadingPhoto { ProgressView() }
                        }
                    }
                    .disabled(isReadingPhoto)

                    if !readingMessage.isEmpty {
                        Text(readingMessage).font(.footnote).foregroundStyle(.secondary)
                    }
                } footer: {
                    Text("読み取り後も元の写真を上に表示します。写真と見比べながら、材料や工程の間違いを修正できます。元の写真はレシピ保存時には保存されません。")
                }

                Section("基本情報") {
                    TextField("料理名", text: $recipe.title)
                    LabeledContent("レシピ番号", value: recipe.recipeNumberText)
                    Picker("カテゴリ", selection: $recipe.category) {
                        ForEach(Recipe.standardCategories, id: \.self) { category in
                            Text(localizedCategory(category)).tag(category)
                        }
                    }
                    Picker("出来上がりの単位", selection: yieldUnitBinding) {
                        ForEach(Recipe.yieldUnits, id: \.self) { unit in
                            Text(localizedYieldUnit(unit)).tag(unit)
                        }
                    }
                    HStack {
                        Text("基準の仕上がり量")
                        Spacer()
                        TextField("量", value: yieldAmountBinding, format: .number.precision(.fractionLength(0...2)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 90)
                        Text(recipe.baseYieldUnit == "直径cm" ? "cm" : localizedYieldUnit(recipe.baseYieldUnit))
                            .foregroundStyle(.secondary)
                    }
                    Stepper("調理時間  \(recipe.cookingMinutes)分", value: $recipe.cookingMinutes, in: 5...360, step: 5)
                    Toggle("予熱温度を設定", isOn: preheatEnabledBinding)
                    if recipe.preheatTemperature != nil {
                        Stepper(
                            "予熱  \(recipe.preheatTemperature ?? 180)℃",
                            value: preheatTemperatureBinding,
                            in: 60...300,
                            step: 5
                        )
                        .tint(.orange)
                    }
                }

                Section {
                    if recipe.ingredients.count > 1 {
                        Label("右側の「前へ・後へ」で食材の入力欄を並べ替えられます", systemImage: "arrow.up.arrow.down")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    ForEach($recipe.ingredients) { $ingredient in
                        let ingredientIndex = recipe.ingredients.firstIndex(where: { $0.id == ingredient.id }) ?? 0
                        HStack(alignment: .top, spacing: 10) {
                            VStack(spacing: 8) {
                                HStack {
                                    TextField("食材名", text: $ingredient.name)
                                        .focused($focusedIngredientID, equals: ingredient.id)
                                    Button {
                                        voiceInputTarget = .ingredient(ingredient.id)
                                        voiceInput.toggle(initialText: ingredient.name)
                                    } label: {
                                        Image(systemName: voiceInput.isListening && voiceInputTarget == .ingredient(ingredient.id) ? "waveform.circle.fill" : "mic.circle")
                                    }
                                    .foregroundStyle(.orange)
                                    .accessibilityLabel("食材名を音声入力")
                                }

                                if focusedIngredientID == ingredient.id {
                                    let suggestions = ingredientSuggestions(for: ingredient.name)
                                    if !suggestions.isEmpty {
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 8) {
                                                ForEach(suggestions, id: \.self) { suggestion in
                                                    Button(suggestion) {
                                                        ingredient.name = suggestion
                                                        focusedIngredientID = nil
                                                    }
                                                    .buttonStyle(.bordered)
                                                    .tint(.orange)
                                                }
                                            }
                                        }
                                    }
                                    if let frenchTerm = FrenchCulinaryGlossary.exactMatch(ingredient.name) {
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text("\(frenchTerm.french) ＝ \(frenchTerm.japanese)")
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(.orange)
                                            Text(frenchTerm.meaning)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            if frenchTerm.category == "食材" {
                                                HStack {
                                                    Button("日本語名に変換") {
                                                        ingredient.name = FrenchCulinaryGlossary.primaryJapaneseName(for: frenchTerm)
                                                    }
                                                    .buttonStyle(.bordered)
                                                    Button("フランス語名に変換") {
                                                        ingredient.name = frenchTerm.french
                                                    }
                                                    .buttonStyle(.bordered)
                                                }
                                                .font(.caption.weight(.semibold))
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }

                                TextField(
                                    "用途（例：生地用、ソース用）",
                                    text: Binding(
                                        get: { ingredient.group ?? "" },
                                        set: { ingredient.group = $0.isEmpty ? nil : $0 }
                                    )
                                )
                                .textInputAutocapitalization(.never)

                                HStack {
                                    if !ingredient.isQualitativeAmount {
                                        TextField("分量", value: $ingredient.amount, format: .number)
                                            .keyboardType(.decimalPad)
                                    }
                                    TextField("単位", text: $ingredient.unit)
                                        .textInputAutocapitalization(.never)
                                        .multilineTextAlignment(.trailing)
                                        .frame(minWidth: 58, maxWidth: 90)
                                    Menu {
                                        ForEach(Ingredient.selectableUnits, id: \.self) { unit in
                                            Button(localizedIngredientUnit(unit)) {
                                                ingredient.unit = unit
                                            }
                                        }
                                    } label: {
                                        Label("単位候補", systemImage: "chevron.up.chevron.down")
                                            .labelStyle(.iconOnly)
                                    }
                                    .accessibilityLabel("単位候補から選ぶ")
                                    .onChange(of: ingredient.unit) { _, newUnit in
                                        if ["適量", "少々", "ひとつまみ", "分量外"].contains(newUnit) {
                                            ingredient.amount = 1
                                        }
                                    }
                                }
                            }
                            VStack(spacing: 8) {
                                Button {
                                    moveIngredient(id: ingredient.id, by: -1)
                                } label: {
                                    Label("前へ", systemImage: "arrow.up")
                                        .labelStyle(.iconOnly)
                                        .frame(width: 30, height: 30)
                                }
                                    .disabled(ingredientIndex == 0)
                                    .accessibilityLabel("食材を上へ移動")
                                    .accessibilityHint("この食材の入力欄を一つ前へ移動します")
                                Button {
                                    moveIngredient(id: ingredient.id, by: 1)
                                } label: {
                                    Label("後へ", systemImage: "arrow.down")
                                        .labelStyle(.iconOnly)
                                        .frame(width: 30, height: 30)
                                }
                                    .disabled(ingredientIndex + 1 >= recipe.ingredients.count)
                                    .accessibilityLabel("食材を下へ移動")
                                    .accessibilityHint("この食材の入力欄を一つ後へ移動します")
                            }
                            .buttonStyle(.bordered)
                            .tint(.orange)
                        }
                    }
                    .onDelete { recipe.ingredients.remove(atOffsets: $0) }
                    .onMove { recipe.ingredients.move(fromOffsets: $0, toOffset: $1) }
                    Button("食材を追加", systemImage: "plus.circle") {
                        recipe.ingredients.append(Ingredient(name: "", amount: 0, unit: "g"))
                    }
                } header: {
                    Text("材料")
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("登録後、人数や食材量に合わせて自動計算します。対応する食材は個数からg、gから個数の目安も表示されます。")
                        Text("単位は直接入力または右側の候補から選択できます。矢印で食材を並べ替えられます。")
                        Text("同じ「用途」を続けて設定すると、生地用・ソース用などの見出しで材料を分割できます。")
                    }
                }

                Section {
                    ForEach(recipe.steps.indices, id: \.self) { index in
                        HStack(alignment: .top) {
                            Text("\(index + 1)").font(.headline).foregroundStyle(.orange).frame(width: 26)
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(alignment: .top) {
                                    TextField("工程を入力", text: $recipe.steps[index], axis: .vertical)
                                        .lineLimit(2...5)
                                        .focused($focusedStepIndex, equals: index)
                                    Button {
                                        voiceInputTarget = .step(index)
                                        voiceInput.toggle(initialText: recipe.steps[index])
                                    } label: {
                                        Image(systemName: voiceInput.isListening && voiceInputTarget == .step(index) ? "waveform.circle.fill" : "mic.circle")
                                    }
                                    .foregroundStyle(.orange)
                                    .accessibilityLabel("工程を音声入力")
                                }
                                if focusedStepIndex == index {
                                    let suggestions = stepIngredientSuggestions
                                    if !suggestions.isEmpty {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("レシピの材料候補")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                            ScrollView(.horizontal, showsIndicators: false) {
                                                HStack(spacing: 8) {
                                                    ForEach(suggestions, id: \.self) { suggestion in
                                                        Button(suggestion) {
                                                            insertIngredientSuggestion(suggestion, at: index)
                                                        }
                                                        .buttonStyle(.bordered)
                                                        .tint(.orange)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                ForEach(FrenchCulinaryGlossary.termsFound(in: recipe.steps[index])) { term in
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("\(term.french) ＝ \(term.japanese)")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.orange)
                                        Text(term.meaning).font(.caption2).foregroundStyle(.secondary)
                                    }
                                }
                                Button {
                                    dismissKeyboard()
                                    cookingTermStepIndex = index
                                    showingCookingTermPicker = true
                                } label: {
                                    Label("調理用語を選ぶ", systemImage: "text.book.closed")
                                        .font(.caption.weight(.semibold))
                                }
                            }
                            VStack(spacing: 10) {
                                Button {
                                    guard index > 0 else { return }
                                    withAnimation { recipe.steps.swapAt(index, index - 1) }
                                } label: {
                                    Image(systemName: "arrow.up")
                                }
                                .disabled(index == 0)
                                .accessibilityLabel("工程\(index + 1)を上へ移動")

                                Button {
                                    guard index + 1 < recipe.steps.count else { return }
                                    withAnimation { recipe.steps.swapAt(index, index + 1) }
                                } label: {
                                    Image(systemName: "arrow.down")
                                }
                                .disabled(index + 1 >= recipe.steps.count)
                                .accessibilityLabel("工程\(index + 1)を下へ移動")

                                Button(role: .destructive) {
                                    guard recipe.steps.indices.contains(index) else { return }
                                    withAnimation { recipe.steps.remove(at: index) }
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .accessibilityLabel("工程\(index + 1)を一括削除")
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    .onDelete { recipe.steps.remove(atOffsets: $0) }
                    .onMove { recipe.steps.move(fromOffsets: $0, toOffset: $1) }
                    Button("工程を追加", systemImage: "plus.circle") { recipe.steps.append("") }
                } header: {
                    Text("調理工程")
                } footer: {
                    Text("矢印で工程の順番を変更でき、ゴミ箱でその番号の文章を一括削除できます。別のレシピを参照する工程には「レシピ番号12」のように入力してください。")
                }

                Section("メモ") {
                    TextField("コツ、温度、仕上がりの目安など", text: $recipe.notes, axis: .vertical)
                        .lineLimit(3...7)
                }

                Section("完成写真") {
                    if let preview = finishedPhotoPreview {
                        Image(uiImage: preview)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    PhotosPicker(selection: $selectedFinishedPhoto, matching: .images) {
                        Label(finishedPhotoPreview == nil ? "作った料理の写真を追加" : "完成写真を変更", systemImage: "photo")
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(recipe.title.isEmpty ? "レシピを追加" : "レシピを編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        recipe.title = recipe.title.trimmingCharacters(in: .whitespacesAndNewlines)
                        recipe.ingredients.removeAll { $0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                        recipe.steps = recipe.steps.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
                        onSave(recipe)
                        if let finishedPhotoData {
                            store.saveFinishedPhoto(finishedPhotoData, for: recipe.id)
                        }
                        dismiss()
                    }
                    .disabled(!canSave)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    if focusedIngredientID != nil {
                        Button {
                            focusAdjacentIngredient(by: -1)
                        } label: {
                            Label("前の食材", systemImage: "chevron.up")
                        }
                        .disabled(!canFocusAdjacentIngredient(by: -1))

                        Button {
                            focusAdjacentIngredient(by: 1)
                        } label: {
                            Label("次の食材", systemImage: "chevron.down")
                        }
                        .disabled(!canFocusAdjacentIngredient(by: 1))
                    }
                    Spacer()
                    Button("完了") {
                        focusedIngredientID = nil
                        focusedStepIndex = nil
                        dismissKeyboard()
                    }
                }
            }
            .onChange(of: selectedPhoto) { _, item in
                guard let item else { return }
                readRecipe(from: item)
            }
            .onChange(of: selectedFinishedPhoto) { _, item in
                guard let item else { return }
                Task {
                    guard let data = try? await item.loadTransferable(type: Data.self),
                          let image = UIImage(data: data) else { return }
                    finishedPhotoData = data
                    finishedPhotoPreview = image
                }
            }
            .onChange(of: voiceInput.transcript) { _, text in
                guard let voiceInputTarget else { return }
                switch voiceInputTarget {
                case .ingredient(let id):
                    if let index = recipe.ingredients.firstIndex(where: { $0.id == id }) {
                        recipe.ingredients[index].name = text
                    }
                case .step(let index):
                    if recipe.steps.indices.contains(index) { recipe.steps[index] = text }
                }
            }
            .alert("音声入力", isPresented: Binding(
                get: { !voiceInput.message.isEmpty },
                set: { if !$0 { voiceInput.message = "" } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(voiceInput.message)
            }
            .sheet(isPresented: $showingCookingTermPicker) {
                CookingTermPickerView { insertedText in
                    guard let index = cookingTermStepIndex, recipe.steps.indices.contains(index) else { return }
                    let current = recipe.steps[index].trimmingCharacters(in: .whitespacesAndNewlines)
                    recipe.steps[index] = current.isEmpty ? insertedText : current + " " + insertedText
                    cookingTermStepIndex = nil
                }
            }
            .sheet(isPresented: $showingSourcePhoto) {
                if let sourcePhotoPreview {
                    SourceRecipePhotoView(image: sourcePhotoPreview)
                }
            }
        }
    }

    private func moveIngredient(id: UUID, by offset: Int) {
        guard let currentIndex = recipe.ingredients.firstIndex(where: { $0.id == id }) else { return }
        let destinationIndex = currentIndex + offset
        guard recipe.ingredients.indices.contains(destinationIndex) else { return }
        withAnimation {
            recipe.ingredients.swapAt(currentIndex, destinationIndex)
        }
        if focusedIngredientID == id {
            focusedIngredientID = id
        }
    }

    private func canFocusAdjacentIngredient(by offset: Int) -> Bool {
        guard let focusedIngredientID,
              let currentIndex = recipe.ingredients.firstIndex(where: { $0.id == focusedIngredientID }) else {
            return false
        }
        return recipe.ingredients.indices.contains(currentIndex + offset)
    }

    private func focusAdjacentIngredient(by offset: Int) {
        guard let focusedIngredientID,
              let currentIndex = recipe.ingredients.firstIndex(where: { $0.id == focusedIngredientID }) else { return }
        let destinationIndex = currentIndex + offset
        guard recipe.ingredients.indices.contains(destinationIndex) else { return }
        self.focusedIngredientID = recipe.ingredients[destinationIndex].id
    }

    private func readRecipe(from item: PhotosPickerItem) {
        isReadingPhoto = true
        readingMessage = ""
        Task {
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    throw RecipeOCRError.imageUnavailable
                }
                guard let image = UIImage(data: data) else {
                    throw RecipeOCRError.imageUnavailable
                }
                sourcePhotoPreview = image
                let draft = try await RecipeOCRService.makeDraft(from: data)
                if !draft.title.isEmpty { recipe.title = draft.title }
                if !draft.ingredients.isEmpty { recipe.ingredients = draft.ingredients }
                if !draft.steps.isEmpty { recipe.steps = draft.steps }
                let resultSummary = "材料\(draft.ingredients.count)件・工程\(draft.steps.count)件を読み取りました。"
                readingMessage = draft.needsReview
                    ? resultSummary + " 読みにくい文字があるため、上の元写真と見比べて確認してください。"
                    : resultSummary + " 上の元写真と見比べて確認してください。"
            } catch {
                readingMessage = NSLocalizedString("文字を読み取れませんでした。明るい場所で紙全体を撮影してお試しください。", comment: "")
            }
            isReadingPhoto = false
            selectedPhoto = nil
        }
    }

    private func ingredientSuggestions(for text: String) -> [String] {
        let normalizedInput = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return store.ingredientSuggestions(matching: normalizedInput).filter {
            $0.compare(normalizedInput, options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive]) != .orderedSame
        }
    }

    private var stepIngredientSuggestions: [String] {
        var seen = Set<String>()
        return recipe.ingredients
            .flatMap { FrenchCulinaryGlossary.equivalentIngredientNames(for: $0.name) }
            .filter { name in
                let key = name.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: .current)
                guard !key.isEmpty, !seen.contains(key) else { return false }
                seen.insert(key)
                return true
            }
    }

    private func insertIngredientSuggestion(_ suggestion: String, at index: Int) {
        guard recipe.steps.indices.contains(index) else { return }
        let current = recipe.steps[index]
        if current.isEmpty {
            recipe.steps[index] = suggestion
        } else if current.last?.isWhitespace == true {
            recipe.steps[index] += suggestion
        } else {
            recipe.steps[index] += " \(suggestion)"
        }
        focusedStepIndex = index
    }
}
