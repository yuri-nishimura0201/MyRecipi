import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import UIKit

struct KitchenHubView: View {
    @ObservedObject var store: RecipeStore
    @State private var mode = "買い物"

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("キッチンツール", selection: $mode) {
                    Text("買い物").tag("買い物")
                    Text("仕込み").tag("仕込み")
                    Text("タイマー").tag("タイマー")
                    Text("食材台帳").tag("食材台帳")
                }
                .pickerStyle(.segmented)
                .padding()

                switch mode {
                case "仕込み": PrepListView(store: store)
                case "タイマー": MultiTimerView()
                case "食材台帳": IngredientProfilesView(store: store)
                default: ShoppingListView(store: store)
                }
            }
            .navigationTitle("キッチン")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink { FavoritesView(store: store) } label: {
                        Label("お気に入り", systemImage: "heart.fill")
                    }
                }
            }
        }
    }
}

private struct ShoppingListView: View {
    @ObservedObject var store: RecipeStore
    @State private var choosingRecipes = false

    var body: some View {
        List {
            Section {
                Button { choosingRecipes = true } label: {
                    Label("使うレシピを選ぶ", systemImage: "checklist")
                }
                Text("選択中：\(store.professionalData.shoppingRecipeIDs.count)件")
                    .foregroundStyle(.secondary)
            }

            Section("合算した買い物リスト") {
                if store.shoppingItems.isEmpty {
                    Text("レシピを選ぶと、同じ食材と単位をまとめて表示します。")
                        .foregroundStyle(.secondary)
                }
                ForEach(store.shoppingItems) { item in
                    let checked = store.professionalData.checkedShoppingKeys.contains(item.key)
                    Button { store.toggleShoppingItem(item.key) } label: {
                        HStack {
                            Image(systemName: checked ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(checked ? .green : .orange)
                            VStack(alignment: .leading) {
                                Text(item.name).strikethrough(checked)
                                Text(item.recipeTitles.joined(separator: "・"))
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(item.amount.recipeAmount) \(item.unit)").fontWeight(.semibold)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .sheet(isPresented: $choosingRecipes) {
            NavigationStack {
                List(store.recipes) { recipe in
                    let selected = store.professionalData.shoppingRecipeIDs.contains(recipe.id)
                    Button {
                        store.setShoppingSelection(recipe.id, selected: !selected)
                    } label: {
                        HStack {
                            Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selected ? .orange : .secondary)
                            VStack(alignment: .leading) {
                                Text(recipe.title)
                                Text(recipe.recipeNumberText).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }.buttonStyle(.plain)
                }
                .navigationTitle("レシピを選択")
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完了") { choosingRecipes = false } } }
            }
        }
    }
}

private struct PrepListView: View {
    @ObservedObject var store: RecipeStore

    private var selectedRecipes: [Recipe] {
        store.recipes.filter { store.professionalData.shoppingRecipeIDs.contains($0.id) }
    }

    var body: some View {
        List {
            if selectedRecipes.isEmpty {
                ContentUnavailableView("レシピが未選択です", systemImage: "list.bullet.clipboard", description: Text("買い物タブで仕込むレシピを選んでください。"))
            }
            ForEach(selectedRecipes) { recipe in
                Section("\(recipe.recipeNumberText)  \(recipe.title)") {
                    ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                        let key = "\(recipe.id.uuidString)-\(index)"
                        let checked = store.professionalData.checkedPrepKeys.contains(key)
                        Button { store.togglePrepItem(key) } label: {
                            HStack(alignment: .top) {
                                Image(systemName: checked ? "checkmark.square.fill" : "square")
                                    .foregroundStyle(checked ? .green : .orange)
                                Text(step).strikethrough(checked).foregroundStyle(.primary)
                            }
                        }.buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

private struct KitchenTimer: Identifiable {
    let id = UUID()
    var name: String
    var seconds: Int
    var endDate: Date?
}

struct MultiTimerView: View {
    @State private var timers: [KitchenTimer] = []
    @State private var name = ""
    @State private var minutes = 5

    var body: some View {
        List {
            Section("タイマーを追加") {
                TextField("工程名（例：生地を休ませる）", text: $name)
                Stepper("\(minutes)分", value: $minutes, in: 1...360)
                Button("タイマーを追加", systemImage: "plus.circle") {
                    timers.append(KitchenTimer(name: name.isEmpty ? "タイマー" : name, seconds: minutes * 60))
                    name = ""
                }
            }
            Section("同時タイマー") {
                ForEach($timers) { $timer in
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        let remaining = max(0, timer.endDate.map { Int($0.timeIntervalSince(context.date)) } ?? timer.seconds)
                        HStack {
                            VStack(alignment: .leading) {
                                Text(timer.name).font(.headline)
                                Text(String(format: "%02d:%02d", remaining / 60, remaining % 60))
                                    .font(.title3.monospacedDigit())
                                    .foregroundStyle(remaining == 0 && timer.endDate != nil ? .red : .orange)
                            }
                            Spacer()
                            Button(timer.endDate == nil ? "開始" : "再開") {
                                timer.endDate = Date().addingTimeInterval(TimeInterval(max(remaining, timer.seconds)))
                            }.buttonStyle(.borderedProminent).tint(.orange)
                        }
                    }
                }
                .onDelete { timers.remove(atOffsets: $0) }
            }
        }
    }
}

struct IngredientProfilesView: View {
    @ObservedObject var store: RecipeStore
    @State private var editingProfile: IngredientProfile?
    @State private var newName = ""

    var body: some View {
        List {
            Section("食材を追加") {
                TextField("食材名", text: $newName)
                Button("価格・歩留まりを登録", systemImage: "plus") {
                    let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    editingProfile = store.profile(for: trimmed) ?? IngredientProfile(name: trimmed)
                    newName = ""
                }
            }
            Section("登録済み") {
                ForEach(store.professionalData.ingredientProfiles) { profile in
                    Button { editingProfile = profile } label: {
                        VStack(alignment: .leading) {
                            Text(profile.name).foregroundStyle(.primary)
                            Text("\(profile.packageAmount.recipeAmount) \(profile.packageUnit)・¥\(Int(profile.packagePrice))・歩留まり \(profile.yieldPercent.recipeAmount)%")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .sheet(item: $editingProfile) { profile in
            IngredientProfileEditor(profile: profile) { store.saveProfile($0) }
        }
    }
}

private struct IngredientProfileEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State var profile: IngredientProfile
    let onSave: (IngredientProfile) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("購入価格") {
                    TextField("食材名", text: $profile.name)
                    TextField("購入価格（円）", value: $profile.packagePrice, format: .number).keyboardType(.decimalPad)
                    TextField("内容量", value: $profile.packageAmount, format: .number).keyboardType(.decimalPad)
                    TextField("単位", text: $profile.packageUnit)
                    TextField("歩留まり（%）", value: $profile.yieldPercent, format: .number).keyboardType(.decimalPad)
                }
                Section("安全・代替") {
                    TextField("アレルゲン（読点区切り）", text: $profile.allergens)
                    TextField("代替食材", text: $profile.substitute, axis: .vertical)
                    Stepper("冷蔵 \(profile.refrigeratedDays)日", value: $profile.refrigeratedDays, in: 0...365)
                    Stepper("冷凍 \(profile.frozenDays)日", value: $profile.frozenDays, in: 0...730)
                }
            }
            .navigationTitle(profile.name)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("保存") { onSave(profile); dismiss() } }
            }
        }
    }
}

struct RecipeProfessionalView: View {
    @ObservedObject var store: RecipeStore
    let recipe: Recipe
    @State private var record = CookingRecord(recipeID: UUID())
    @State private var stepPhotoItem: PhotosPickerItem?
    @State private var stepPhotoIndex = 0
    @State private var recordPhotoItem: PhotosPickerItem?
    @State private var recordPhotoData: Data?
    @State private var pdfDocument = DataExportDocument(contentType: .pdf)
    @State private var exportingPDF = false

    private var reverseLinks: [Recipe] {
        guard let number = recipe.recipeNumber else { return [] }
        let patterns = ["レシピ番号\(number)", "レシピ \(number)", "No.\(number)", "#\(number)"]
        return store.recipes.filter { candidate in
            candidate.id != recipe.id && candidate.steps.contains { step in
                patterns.contains { step.localizedCaseInsensitiveContains($0) }
            }
        }
    }

    private var allergens: [String] {
        Array(Set(recipe.ingredients.flatMap { ingredient in
            KitchenKnowledge.allergens(for: ingredient.name, custom: store.profile(for: ingredient.name)?.allergens ?? "")
        })).sorted()
    }

    private var flourTotal: Double {
        recipe.ingredients.filter {
            $0.name.contains("粉") || $0.name.localizedCaseInsensitiveContains("farine")
        }.reduce(0) { $0 + KitchenKnowledge.normalizedAmount($1.amount, unit: $1.unit).0 }
    }

    @ViewBuilder private var costSections: some View {
        Section("原価・歩留まり") {
            LabeledContent("合計原価", value: "¥\(Int(store.totalCost(for: recipe).rounded()))")
            LabeledContent("1\(localizedYieldUnit(recipe.baseYieldUnit))あたり", value: "¥\(Int((store.totalCost(for: recipe) / recipe.baseYieldAmount).rounded()))")
            NavigationLink("食材の価格を登録") { IngredientProfilesView(store: store) }
        }
        if flourTotal > 0 {
            BakerPercentageSection(recipe: recipe, flourTotal: flourTotal)
        }
    }

    @ViewBuilder private var safetySection: some View {
        Section("アレルゲン・保存・代替") {
            Text(allergens.isEmpty ? "自動検出されたアレルゲンはありません" : allergens.joined(separator: "・"))
                .foregroundStyle(allergens.isEmpty ? Color.secondary : Color.red)
            ForEach(recipe.ingredients) { ingredient in
                IngredientSafetyRow(ingredient: ingredient, profile: store.profile(for: ingredient.name))
            }
        }
    }

    @ViewBuilder private var photoSection: some View {
        Section("工程写真・タイムライン") {
            ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                StepPhotoRow(
                    store: store,
                    recipe: recipe,
                    index: index,
                    step: step,
                    selectedItem: Binding(
                        get: { stepPhotoIndex == index ? stepPhotoItem : nil },
                        set: { stepPhotoIndex = index; stepPhotoItem = $0 }
                    )
                )
            }
            NavigationLink("工程を見ながら同時タイマーを使う") {
                MultiTimerView().navigationTitle(recipe.title)
            }
        }
    }

    @ViewBuilder private var recordSection: some View {
        Section("今回の調理記録") {
            DatePicker("作成日", selection: $record.createdAt, displayedComponents: .date)
            TextField("仕込み重量（g）", value: $record.preparedWeight, format: .number).keyboardType(.decimalPad)
            TextField("完成重量・出来上がり量", value: $record.actualYield, format: .number).keyboardType(.decimalPad)
            if let loss = record.lossPercent {
                LabeledContent("ロス率", value: "\(loss.formatted(.number.precision(.fractionLength(0...1))))%")
            }
            Stepper("焼成 \(record.bakeTemperature)℃", value: $record.bakeTemperature, in: 0...350, step: 5)
            Stepper("焼成 \(record.bakeMinutes)分", value: $record.bakeMinutes, in: 0...600, step: 5)
            Stepper("評価 \(record.rating)/5", value: $record.rating, in: 1...5)
            TextField("反省点・次回の調整", text: $record.notes, axis: .vertical)
            PhotosPicker(selection: $recordPhotoItem, matching: .images) {
                Label(recordPhotoData == nil ? "今回の写真を追加" : "写真を選択済み", systemImage: "photo")
            }
            Button("記録を保存", systemImage: "square.and.arrow.down") {
                record.recipeID = recipe.id
                store.addCookingRecord(record, photoData: recordPhotoData)
                record = CookingRecord(recipeID: recipe.id)
                recordPhotoData = nil
            }
            ForEach(store.records(for: recipe.id)) { item in
                CookingRecordRow(store: store, record: item)
            }
        }
    }

    @ViewBuilder private var historySections: some View {
        if !reverseLinks.isEmpty {
            Section("このレシピを使っているレシピ") {
                ForEach(reverseLinks) { linked in
                    NavigationLink("\(linked.recipeNumberText)  \(linked.title)") {
                        RecipeDetailView(store: store, recipeID: linked.id)
                    }
                }
            }
        }
        Section("履歴・出力") {
            ForEach(store.versions(for: recipe.id)) { version in
                NavigationLink {
                    RecipeVersionComparisonView(store: store, current: recipe, version: version)
                } label: {
                    Text("\(version.savedAt.formatted(date: .abbreviated, time: .shortened)) の版と比較")
                }
            }
            Button("レシピを複製", systemImage: "doc.on.doc") { store.duplicate(recipe) }
            Button("PDFとして保存", systemImage: "doc.richtext") {
                pdfDocument = DataExportDocument(data: RecipePDF.make(recipe: recipe), contentType: .pdf)
                exportingPDF = true
            }
        }
    }

    var body: some View {
        List {
            costSections
            safetySection
            photoSection
            recordSection
            historySections
        }
        .navigationTitle("専門ツール")
        .onChange(of: stepPhotoItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    store.saveStepPhoto(data, recipeID: recipe.id, stepIndex: stepPhotoIndex)
                }
                stepPhotoItem = nil
            }
        }
        .onChange(of: recordPhotoItem) { _, item in
            guard let item else { return }
            Task { recordPhotoData = try? await item.loadTransferable(type: Data.self) }
        }
        .fileExporter(isPresented: $exportingPDF, document: pdfDocument, contentType: .pdf, defaultFilename: recipe.title) { _ in }
    }
}

private struct BakerPercentageSection: View {
    let recipe: Recipe
    let flourTotal: Double
    var body: some View {
        Section("ベーカーズパーセント") {
            ForEach(recipe.ingredients) { ingredient in
                let grams = KitchenKnowledge.normalizedAmount(ingredient.amount, unit: ingredient.unit)
                if grams.1 == "g" {
                    let percent = grams.0 / flourTotal * 100
                    LabeledContent(ingredient.name, value: "\(percent.formatted(.number.precision(.fractionLength(0...1))))%")
                }
            }
            Text("小麦粉類の合計を100%として計算します。").font(.caption).foregroundStyle(.secondary)
        }
    }
}

private struct IngredientSafetyRow: View {
    let ingredient: Ingredient
    let profile: IngredientProfile?
    private var substitute: String? {
        profile?.substitute.isEmpty == false ? profile?.substitute : KitchenKnowledge.substitute(for: ingredient.name)
    }
    var body: some View {
        if substitute != nil || (profile?.refrigeratedDays ?? 0) > 0 || (profile?.frozenDays ?? 0) > 0 {
            VStack(alignment: .leading, spacing: 3) {
                Text(ingredient.name).font(.headline)
                if let substitute { Text("代替：\(substitute)") }
                if let profile, profile.refrigeratedDays > 0 || profile.frozenDays > 0 {
                    Text("保存目安：冷蔵\(profile.refrigeratedDays)日／冷凍\(profile.frozenDays)日")
                }
            }.font(.caption)
        }
    }
}

private struct StepPhotoRow: View {
    @ObservedObject var store: RecipeStore
    let recipe: Recipe
    let index: Int
    let step: String
    @Binding var selectedItem: PhotosPickerItem?
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("\(index + 1). \(step)")
            if let image = store.stepPhoto(recipeID: recipe.id, stepIndex: index) {
                Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 160).clipShape(RoundedRectangle(cornerRadius: 10))
            }
            PhotosPicker(selection: $selectedItem, matching: .images) {
                Label("この工程の写真を追加", systemImage: "camera")
            }.font(.caption)
        }
    }
}

private struct CookingRecordRow: View {
    @ObservedObject var store: RecipeStore
    let record: CookingRecord
    var body: some View {
        VStack(alignment: .leading) {
            if let image = store.cookingRecordPhoto(record) {
                Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 180).clipShape(RoundedRectangle(cornerRadius: 10))
            }
            Text(record.createdAt.formatted(date: .abbreviated, time: .omitted)).font(.headline)
            Text("評価 \(record.rating)/5　\(record.bakeTemperature)℃・\(record.bakeMinutes)分")
            if let loss = record.lossPercent {
                Text("仕込み \(record.preparedWeight.recipeAmount)g → 完成 \(record.actualYield.recipeAmount)g（ロス \(loss.formatted(.number.precision(.fractionLength(0...1))))%）")
            }
            if !record.notes.isEmpty { Text(record.notes).foregroundStyle(.secondary) }
        }
    }
}

private struct RecipeVersionComparisonView: View {
    @ObservedObject var store: RecipeStore
    let current: Recipe
    let version: RecipeVersion
    var body: some View {
        List {
            Section("基本情報") {
                comparison("料理名", old: version.recipe.title, new: current.title)
                comparison("カテゴリ", old: version.recipe.category, new: current.category)
                comparison("調理時間", old: "\(version.recipe.cookingMinutes)分", new: "\(current.cookingMinutes)分")
                comparison("出来上がり", old: version.recipe.yieldDescription, new: current.yieldDescription)
            }
            Section("内容") {
                comparison("材料数", old: "\(version.recipe.ingredients.count)", new: "\(current.ingredients.count)")
                comparison("工程数", old: "\(version.recipe.steps.count)", new: "\(current.steps.count)")
                Text("旧版の材料：\n" + version.recipe.ingredients.map { "\($0.name) \($0.amountDescription())" }.joined(separator: "\n"))
                Text("現在の材料：\n" + current.ingredients.map { "\($0.name) \($0.amountDescription())" }.joined(separator: "\n"))
            }
            Button("この版へ戻す") { store.restoreVersion(version) }
                .foregroundStyle(.orange)
        }
        .navigationTitle("版を比較")
    }

    private func comparison(_ title: String, old: String, new: String) -> some View {
        VStack(alignment: .leading) {
            Text(title).font(.headline)
            Text("旧：\(old)").foregroundStyle(.secondary)
            Text("現：\(new)").foregroundStyle(old == new ? Color.secondary : Color.orange)
        }
    }
}

struct DataExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.pdf, .commaSeparatedText, .json] }
    var data = Data()
    var contentType: UTType = .data

    init(data: Data = Data(), contentType: UTType) { self.data = data; self.contentType = contentType }
    init(configuration: ReadConfiguration) throws { data = configuration.file.regularFileContents ?? Data() }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}

enum RecipePDF {
    static func make(recipe: Recipe) -> Data {
        let page = CGRect(x: 0, y: 0, width: 595, height: 842)
        return UIGraphicsPDFRenderer(bounds: page).pdfData { context in
            context.beginPage()
            var y: CGFloat = 42
            func draw(_ text: String, size: CGFloat = 12, bold: Bool = false) {
                let font = bold ? UIFont.boldSystemFont(ofSize: size) : UIFont.systemFont(ofSize: size)
                let rect = CGRect(x: 42, y: y, width: 511, height: 200)
                let bounds = (text as NSString).boundingRect(with: rect.size, options: [.usesLineFragmentOrigin], attributes: [.font: font], context: nil)
                (text as NSString).draw(in: CGRect(x: 42, y: y, width: 511, height: bounds.height + 4), withAttributes: [.font: font])
                y += bounds.height + 9
                if y > 790 { context.beginPage(); y = 42 }
            }
            draw(recipe.title, size: 24, bold: true)
            draw("\(recipe.recipeNumberText)　\(recipe.category)　\(recipe.yieldDescription)")
            draw("材料", size: 17, bold: true)
            recipe.ingredients.forEach { draw("\($0.name)　\($0.amountDescription())") }
            draw("作り方", size: 17, bold: true)
            for (index, step) in recipe.steps.enumerated() { draw("\(index + 1). \(step)") }
            if !recipe.notes.isEmpty { draw("メモ", size: 17, bold: true); draw(recipe.notes) }
        }
    }
}

struct RecentlyDeletedView: View {
    @ObservedObject var store: RecipeStore
    var body: some View {
        List {
            ForEach(store.professionalData.recentlyDeleted) { deleted in
                VStack(alignment: .leading) {
                    Text(deleted.recipe.title).font(.headline)
                    Text("削除：\(deleted.deletedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption).foregroundStyle(.secondary)
                    HStack {
                        Button("復元") { store.restoreDeleted(deleted) }.buttonStyle(.borderedProminent).tint(.orange)
                        Button("完全に削除", role: .destructive) { store.permanentlyDelete(deleted) }.buttonStyle(.bordered)
                    }
                }
            }
        }
        .navigationTitle("最近削除した項目")
    }
}
