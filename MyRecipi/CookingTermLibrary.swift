import SwiftUI
import UIKit

struct CookingTerm: Identifiable, Hashable {
    let japanese: String
    let english: String
    let meaning: String
    let category: String
    var id: String { japanese + english }
}

enum CookingTermLibrary {
    static let categories = ["すべて", "加熱", "下処理", "切り方", "製菓", "製パン", "状態・器具"]

    private static let readings: [String: String] = [
        "焼く":"やく", "炒める":"いためる", "揚げる":"あげる", "煮る":"にる", "煮込む":"にこむ",
        "ゆでる":"ゆでる", "蒸す":"むす", "湯せん":"ゆせん", "弱火":"よわび", "中火":"ちゅうび",
        "強火":"つよび", "予熱する":"よねつする", "焼き色を付ける":"やきいろをつける", "煮詰める":"につめる",
        "下ゆでする":"したゆでする", "あくを取る":"あくをとる", "水にさらす":"みずにさらす",
        "水気を切る":"みずけをきる", "裏ごしする":"うらごしする", "こす":"こす", "漬け込む":"つけこむ",
        "もみ込む":"もみこむ", "塩を振る":"しおをふる", "みじん切り":"みじんぎり", "薄切り":"うすぎり",
        "輪切り":"わぎり", "半月切り":"はんげつぎり", "いちょう切り":"いちょうぎり", "乱切り":"らんぎり",
        "角切り":"かくぎり", "千切り":"せんぎり", "そぎ切り":"そぎぎり", "一口大":"ひとくちだい",
        "混ぜる":"まぜる", "さっくり混ぜる":"さっくりまぜる", "泡立てる":"あわだてる",
        "すり混ぜる":"すりまぜる", "ふるう":"ふるう", "こねる":"こねる", "発酵させる":"はっこうさせる",
        "休ませる":"やすませる", "のばす":"のばす", "型に敷き込む":"かたにしきこむ",
        "空焼きする":"からやきする", "粗熱を取る":"あらねつをとる", "冷やし固める":"ひやしかためる"
    ]

    static let terms: [CookingTerm] = [
        item("焼く", "grill / bake / roast", "直火・フライパン・オーブンなどで加熱する。", "加熱"),
        item("炒める", "sauté / stir-fry", "少量の油を使い、混ぜながら比較的短時間で加熱する。", "加熱"),
        item("揚げる", "deep-fry", "高温の油の中で加熱する。", "加熱"),
        item("煮る", "simmer / cook", "調味した液体の中で食材に火を通す。", "加熱"),
        item("煮込む", "stew / simmer", "弱めの火で時間をかけ、味を含ませながら加熱する。", "加熱"),
        item("ゆでる", "boil", "湯や煮立った液体で加熱する。", "加熱"),
        item("蒸す", "steam", "蒸気を使って食材に火を通す。", "加熱"),
        item("湯せん", "bain-marie / water bath", "容器を湯に当て、直接火を当てず穏やかに加熱する。", "加熱"),
        item("弱火", "low heat", "炎や熱量を弱く保って加熱する。", "加熱"),
        item("中火", "medium heat", "強火と弱火の中間の熱量で加熱する。", "加熱"),
        item("強火", "high heat", "強い熱量で短時間に加熱する。", "加熱"),
        item("予熱する", "preheat", "調理前にオーブンや器具を指定温度まで温める。", "加熱"),
        item("焼き色を付ける", "brown / sear", "表面を高温で加熱し、香ばしい色を付ける。", "加熱"),
        item("煮詰める", "reduce", "加熱して水分を蒸発させ、濃度や味を高める。", "加熱"),
        item("下ゆでする", "blanch / parboil", "本調理前に短時間ゆで、あく抜きや火通しを行う。", "下処理"),
        item("あくを取る", "skim", "液面に浮いた泡や不純物を取り除く。", "下処理"),
        item("水にさらす", "soak in water", "水に浸して辛味、でんぷん、あくなどを抜く。", "下処理"),
        item("水気を切る", "drain", "ざるや布などで余分な水分を除く。", "下処理"),
        item("裏ごしする", "purée / pass through a sieve", "こし器に通し、皮や繊維を除いて滑らかにする。", "下処理"),
        item("こす", "strain", "液体をざるやこし器に通して固形物を除く。", "下処理"),
        item("漬け込む", "marinate", "調味液などに一定時間浸して味や香りを移す。", "下処理"),
        item("もみ込む", "massage / rub in", "手で押し混ぜ、調味料を食材になじませる。", "下処理"),
        item("塩を振る", "season with salt", "食材の表面へ塩を均一に振る。", "下処理"),
        item("みじん切り", "mince / finely chop", "食材を非常に細かく刻む。", "切り方"),
        item("薄切り", "thinly slice", "食材を薄く切る。", "切り方"),
        item("輪切り", "cut into rounds", "円筒形の食材を断面が円になるよう切る。", "切り方"),
        item("半月切り", "half-moon slices", "縦半分にしてから、断面が半月形になるよう切る。", "切り方"),
        item("いちょう切り", "quarter-round slices", "縦に四つ割りしてから薄く切る。", "切り方"),
        item("乱切り", "rangiri / irregular chunks", "食材を回しながら斜めに切り、表面積を広くする。", "切り方"),
        item("角切り", "dice", "食材を立方体状に切る。", "切り方"),
        item("千切り", "julienne / shred", "食材を細長く均一に切る。", "切り方"),
        item("そぎ切り", "sogigiri / diagonal slice", "包丁を寝かせ、食材をそぐように斜めに切る。", "切り方"),
        item("一口大", "bite-size pieces", "一口で食べやすい大きさに切る。", "切り方"),
        item("混ぜる", "mix / stir", "材料を均一になるよう合わせる。", "製菓"),
        item("さっくり混ぜる", "fold gently", "泡をつぶさないよう、底から返して軽く混ぜる。", "製菓"),
        item("泡立てる", "whisk / whip", "空気を抱き込ませながら混ぜ、体積を増やす。", "製菓"),
        item("すり混ぜる", "cream together", "材料をすり合わせ、滑らかな状態にする。", "製菓"),
        item("ふるう", "sift", "粉類をふるいに通し、だまを除いて空気を含ませる。", "製菓"),
        item("こねる", "knead", "生地を押し、折り、伸ばして均一にする。", "製菓"),
        item("発酵させる", "proof / ferment", "酵母などの働きで生地を膨らませ、風味を作る。", "製菓"),
        item("休ませる", "rest / chill", "生地や材料を一定時間置き、状態を安定させる。", "製菓"),
        item("のばす", "roll out", "麺棒などで生地を目的の厚さに広げる。", "製菓"),
        item("型に敷き込む", "line a mould / pan", "のばした生地を型の底と側面へ沿わせる。", "製菓"),
        item("空焼きする", "blind bake", "フィリングを入れずにタルト生地などを先に焼く。", "製菓"),
        item("粗熱を取る", "cool slightly", "加熱直後の強い熱を、室温などである程度冷ます。", "製菓"),
        item("冷やし固める", "chill until set", "冷蔵・冷凍により形を保てる状態まで固める。", "製菓")
    ]

    static func search(_ query: String, category: String) -> [CookingTerm] {
        let key = normalize(query)
        return terms.filter { term in
            let categoryMatches = category == "すべて" || term.category == category
            let queryMatches = key.isEmpty || normalize(term.japanese).contains(key) ||
                normalize(readings[term.japanese] ?? "").contains(key) ||
                normalize(term.english).contains(key) || normalize(term.meaning).contains(key)
            return categoryMatches && queryMatches
        }
    }

    private static func normalize(_ text: String) -> String {
        let katakana = text.applyingTransform(.hiraganaToKatakana, reverse: false) ?? text
        return katakana.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: .current)
            .replacingOccurrences(of: #"[\s\-_/]"#, with: "", options: .regularExpression)
    }

    private static func item(_ ja: String, _ en: String, _ meaning: String, _ category: String) -> CookingTerm {
        CookingTerm(japanese: ja, english: en, meaning: meaning, category: category)
    }
}

struct CookingTermPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var category = "すべて"
    @State private var customFrenchTerms = UserCulinaryDictionary.load()
    @State private var showingAddTerm = false
    let onSelect: (String) -> Void

    private var results: [CookingTerm] { CookingTermLibrary.search(query, category: category) }

    private var frenchResults: [FrenchCulinaryTerm] {
        let all = FrenchCulinaryGlossary.terms + customFrenchTerms.map(\.glossaryTerm)
        let categoryFiltered = all.filter { term in
            guard term.category != "食材" else { return false }
            if category == "すべて" { return true }
            switch category {
            case "製菓", "製パン", "状態・器具": return term.category == category
            default: return term.category == "調理技法"
            }
        }
        return query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? categoryFiltered
            : FrenchCulinaryGlossary.matches(query, in: categoryFiltered, limit: categoryFiltered.count)
    }

    var body: some View {
        NavigationStack {
            List {
                Picker("種類", selection: $category) {
                    ForEach(CookingTermLibrary.categories, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.menu)

                Section("基本用語") {
                    ForEach(results) { term in
                        Button {
                            onSelect(term.japanese)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(term.japanese).font(.headline).foregroundStyle(.primary)
                                if let reading = CookingTermLibrary.reading(for: term) {
                                    Text(reading).font(.caption).foregroundStyle(.secondary)
                                }
                                Text(term.english).font(.subheadline).foregroundStyle(.orange)
                                Text(term.meaning).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("フランス料理用語") {
                    ForEach(frenchResults) { term in
                        Button {
                            onSelect("\(term.french)（\(FrenchCulinaryGlossary.primaryJapaneseName(for: term))）")
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(term.french).font(.headline).foregroundStyle(.primary)
                                Text("\(term.reading)・\(term.japanese)")
                                    .font(.subheadline).foregroundStyle(.orange)
                                Text(term.meaning).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("調理用語を選ぶ")
            .searchable(text: $query, prompt: "日本語・英語・仏語・読み方で検索")
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("閉じる") { dismiss() } }
                ToolbarItem(placement: .primaryAction) {
                    Button { showingAddTerm = true } label: {
                        Label("辞書に追加", systemImage: "plus")
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完了") { dismissKeyboard() }
                }
            }
            .sheet(isPresented: $showingAddTerm) {
                AddFrenchCulinaryTermView { term in
                    customFrenchTerms.removeAll {
                        $0.french.compare(term.french, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
                    }
                    customFrenchTerms.append(term)
                    UserCulinaryDictionary.save(customFrenchTerms)
                }
            }
        }
    }
}

extension CookingTermLibrary {
    static func reading(for term: CookingTerm) -> String? {
        readings[term.japanese]
    }
}

func dismissKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}
