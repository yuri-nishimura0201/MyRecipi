import SwiftUI

struct FrenchCulinaryTerm: Identifiable, Hashable {
    let french: String
    let reading: String
    let japanese: String
    let meaning: String
    let category: String
    let source: String
    var id: String { french + category }
}

struct UserFrenchCulinaryTerm: Identifiable, Codable, Hashable {
    var id = UUID()
    var french: String
    var reading: String
    var japanese: String
    var meaning: String
    var category: String

    var glossaryTerm: FrenchCulinaryTerm {
        FrenchCulinaryTerm(
            french: french,
            reading: reading,
            japanese: japanese,
            meaning: meaning,
            category: category,
            source: "ユーザー追加"
        )
    }
}

enum UserCulinaryDictionary {
    private static let storageKey = "myrecipi.userFrenchCulinaryTerms.v1"

    static func load() -> [UserFrenchCulinaryTerm] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let terms = try? JSONDecoder().decode([UserFrenchCulinaryTerm].self, from: data) else { return [] }
        return terms
    }

    static func save(_ terms: [UserFrenchCulinaryTerm]) {
        guard let data = try? JSONEncoder().encode(terms) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}

enum FrenchCulinaryGlossary {
    static let categories = ["すべて", "食材", "調理技法", "製菓", "製パン", "状態・器具"]

    static var allTerms: [FrenchCulinaryTerm] {
        terms + UserCulinaryDictionary.load().map(\.glossaryTerm)
    }

    static let terms: [FrenchCulinaryTerm] = [
        term("beurre", "ブール", "バター", "牛乳のクリームから作る乳脂肪。beurre douxは無塩、beurre demi-selは有塩。", "食材"),
        term("farine", "ファリーヌ", "小麦粉", "通常は小麦粉。フランスのT45、T55などは灰分量による分類。数字が小さいほど白い粉。", "食材"),
        term("farine faible", "ファリーヌ・フェーブル", "薄力粉", "たんぱく質とグルテンの力が弱い小麦粉。ビスキュイ、クッキー、ケーキなどに向く。日本の薄力粉に対応させやすい表現。", "食材"),
        term("farine de blé tout usage", "ファリーヌ・ド・ブレ・トゥ・ユザージュ", "中力粉／万能小麦粉", "パン用と菓子用の中間程度に使える小麦粉。国や製品でたんぱく量が異なるため、用途と成分を確認する。", "食材"),
        term("farine de force", "ファリーヌ・ド・フォルス", "強力粉", "グルテンを形成する力が強い小麦粉。パン、ブリオッシュ、発酵生地などに使う。farine forteとも表現する。", "食材"),
        term("farine de gruau", "ファリーヌ・ド・グリュオ", "グリュオ粉／高たんぱく小麦粉", "良質の軟質小麦から作る力の強い粉。ブリオッシュ、クロワッサン、発酵菓子など伸展性が必要な生地に用いる。", "食材"),
        term("farine T45", "ファリーヌ・テ・キャラントサンク", "T45小麦粉／製菓用小麦粉", "フランスで灰分量が低い白い小麦粉。製菓によく使うが、T番号は灰分分類であり、日本の薄力粉・強力粉の区分とは一致しない。", "食材"),
        term("farine T55", "ファリーヌ・テ・サンカンサンク", "T55小麦粉／フランスの汎用小麦粉", "フランスで料理、ビスキュイ、タルト、白パンなどに広く使う白い小麦粉。たんぱく量は製品ごとに確認する。", "食材"),
        term("farine T65", "ファリーヌ・テ・ソワサントサンク", "T65小麦粉／フランスパン用小麦粉", "T45・T55より灰分が多く、小麦の風味が残る。バゲットや各種パン、タルトなどに使われる。", "食材"),
        term("farine complète", "ファリーヌ・コンプレット", "全粒粉", "ふすまや胚芽を多く含む小麦粉。フランスのT150は全粒粉に相当する代表的な区分。", "食材"),
        term("farine de seigle", "ファリーヌ・ド・セーグル", "ライ麦粉", "ライ麦を挽いた粉。酸味と独特の香りがあり、パンや菓子に使う。", "食材"),
        term("farine de riz", "ファリーヌ・ド・リ", "米粉", "米を挽いた粉。菓子、パン、ソースのつなぎなどに使う。粒度や製粉方法で性質が異なる。", "食材"),
        term("farine de sarrasin", "ファリーヌ・ド・サラザン", "そば粉", "そばの実を挽いた粉。ガレット・ブルトンヌなどに使う。blé noirとも呼ばれる。", "食材"),
        term("fécule de pomme de terre", "フェキュル・ド・ポム・ド・テール", "片栗粉／じゃがいもでんぷん", "じゃがいも由来のでんぷん。日本の市販片栗粉の一般的な原料で、とろみ付けや軽い生地に使う。", "食材"),
        term("chapelure", "シャプルール", "パン粉", "乾燥または生のパンを細かくしたもの。衣、詰め物、グラタンの表面などに使う。", "食材"),
        term("œuf", "ウフ", "卵", "単数はœuf、複数œufs。jaune d’œufは卵黄、blanc d’œufは卵白。", "食材"),
        term("œuf entier", "ウフ・アンティエ", "全卵", "卵黄と卵白を分けずに合わせた卵。製菓では殻を除いた重量で指定されることが多い。", "食材"),
        term("jaune d’œuf", "ジョーヌ・ドゥフ", "卵黄／黄身", "卵の黄色い部分。乳化、濃度付け、焼き色、コク付けなどに使う。", "食材"),
        term("blanc d’œuf", "ブラン・ドゥフ", "卵白／白身", "卵の透明な部分。泡立ててメレンゲにするほか、つなぎや澄ましにも使う。", "食材"),
        term("lait", "レ", "牛乳", "乳。lait entierは全乳、lait demi-écréméは半脱脂乳。", "食材"),
        term("lait entier", "レ・アンティエ", "全乳／成分無調整牛乳", "乳脂肪を除いていない牛乳。製菓やソースではコクと乳化性を与える。", "食材"),
        term("lait demi-écrémé", "レ・ドゥミ・エクレメ", "半脱脂乳", "乳脂肪の一部を除いた牛乳。フランスで日常的に使われる。", "食材"),
        term("lait écrémé", "レ・エクレメ", "脱脂乳", "乳脂肪のほとんどを除いた牛乳。", "食材"),
        term("lait en poudre", "レ・アン・プードル", "粉乳／脱脂粉乳", "牛乳から水分を除いて粉末にしたもの。パンや菓子の風味、焼き色、保水性を補う。", "食材"),
        term("crème liquide entière", "クレーム・リキッド・アンティエール", "生クリーム／動物性生クリーム", "液状で乳脂肪分の高いクリーム。泡立て、ガナッシュ、ソースなどに使う。脂肪分を確認する。", "食材"),
        term("crème fleurette", "クレーム・フルーレット", "フルーレット／泡立て用生クリーム", "低温殺菌された液状クリームを指すことが多い。泡立てや製菓に使われるが、製品表示の脂肪分を確認する。", "食材"),
        term("crème fraîche", "クレーム・フレッシュ", "クレーム・フレッシュ／発酵クリーム", "フランスでは加熱殺菌条件を満たすフレッシュなクリームの総称としても使う。épaisseは濃厚、liquideは液状。", "食材"),
        term("beurre doux", "ブール・ドゥー", "無塩バター", "食塩を加えていないバター。製菓では塩分を配合どおり管理しやすい。", "食材"),
        term("beurre demi-sel", "ブール・ドゥミ・セル", "有塩バター", "少量の塩を含むバター。製品ごとに塩分が異なる。", "食材"),
        term("beurre sec", "ブール・セック", "低水分バター／折り込み用バター", "一般的なバターより水分が少なく融点が高めで、フィユタージュやクロワッサンの折り込みに適する。", "食材"),
        term("beurre de tourage", "ブール・ド・トゥラージュ", "折り込み用バター", "クロワッサンや折り込みパイの層を作るため、可塑性と融点を調整した業務用バター。", "食材"),
        term("fromage blanc", "フロマージュ・ブラン", "フロマージュブラン", "凝乳を水切りした白くやわらかいフレッシュチーズ。デザート、クリーム、ソースに使う。", "食材"),
        term("fromage à la crème", "フロマージュ・ア・ラ・クレーム", "クリームチーズ", "クリームを加えた濃厚なフレッシュチーズ。チーズケーキやクリームに使う。", "食材"),
        term("sucre glace", "シュクル・グラス", "粉砂糖", "非常に細かく挽いた砂糖。仕上げ、アイシング、パート・シュクレに使う。", "食材"),
        term("sucre semoule", "シュクル・スムール", "グラニュー糖", "粒の細かい結晶糖。製菓で一般的に使われる。", "食材"),
        term("sucre blanc japonais", "シュクル・ブラン・ジャポネ", "上白糖", "日本特有のしっとりした白砂糖。フランスに完全な同等品は少ないため、レシピ翻訳ではjōhakutōと補足すると明確。", "食材"),
        term("cassonade", "カソナード", "カソナード／粗糖", "本来はさとうきび由来の未精製または部分精製の褐色糖。香ばしい風味がある。", "食材"),
        term("vergeoise", "ヴェルジョワーズ", "ヴェルジョワーズ／てんさい糖の褐色糖", "甜菜糖のシロップを再結晶させた、しっとりした褐色糖。北フランスやベルギーの菓子に使う。", "食材"),
        term("sucre roux", "シュクル・ルー", "きび砂糖／褐色糖", "褐色の砂糖の総称。原料や精製度は製品により異なるため、cassonadeやvergeoiseと区別して確認する。", "食材"),
        term("sucre muscovado", "シュクル・ムスコヴァド", "黒糖／マスコバド糖", "糖蜜分を多く残した濃色で香りの強い含蜜糖。日本の黒糖とは製法・風味が完全には同じでない。", "食材"),
        term("sirop de glucose", "シロ・ド・グリュコーズ", "水あめ／グルコースシロップ", "でんぷんを糖化した粘度のある糖液。結晶防止、保湿、食感調整に使う。", "食材"),
        term("sucre inverti", "シュクル・アンヴェルティ", "転化糖", "ショ糖をブドウ糖と果糖へ分解した糖。保湿性が高く、結晶防止や柔らかさの維持に使う。", "食材"),
        term("levure chimique", "ルヴュール・シミック", "ベーキングパウダー", "化学膨張剤。パン酵母のlevure boulangèreとは別物。", "食材"),
        term("levure boulangère", "ルヴュール・ブーランジェール", "パン酵母", "パン生地を発酵させる酵母。fraîcheは生、sècheはドライ。", "食材"),
        term("levure fraîche", "ルヴュール・フレッシュ", "生イースト", "水分を含む生のパン酵母。冷蔵管理し、ドライイーストとは使用量を換算する。", "食材"),
        term("levure sèche", "ルヴュール・セッシュ", "ドライイースト", "乾燥させたパン酵母。instantanéeはインスタント、activeは予備発酵が必要な製品がある。", "食材"),
        term("bicarbonate de sodium", "ビカルボナット・ド・ソディウム", "重曹／炭酸水素ナトリウム", "酸性材料と反応してガスを発生する膨張剤。入れ過ぎるとアルカリ臭や着色が強くなる。", "食材"),
        term("crème de tartre", "クレーム・ド・タルトル", "クリームタータ／酒石酸水素カリウム", "卵白の泡を安定させる、砂糖の結晶化を抑えるなどの目的で使う酸性粉末。", "食材"),
        term("fécule de maïs", "フェキュル・ド・マイス", "コーンスターチ", "とうもろこし由来のでんぷん。とろみ付けや軽い生地に使う。", "食材"),
        term("poudre d’amandes", "プードル・ダマンド", "アーモンドプードル", "アーモンドを粉末にしたもの。タルト、ダックワーズ、マカロンなどに使う。", "食材"),
        term("poudre de noisettes", "プードル・ド・ノワゼット", "ヘーゼルナッツパウダー", "ヘーゼルナッツを粉末にしたもの。焼き菓子、クリーム、プラリネなどに使う。", "食材"),
        term("cacao en poudre", "カカオ・アン・プードル", "ココアパウダー", "カカオマスから一部の脂肪を除いて粉末にしたもの。無糖か加糖かを確認する。", "食材"),
        term("chocolat noir", "ショコラ・ノワール", "ダークチョコレート", "カカオ分の高いチョコレート。pourcentage de cacaoで配合が変わるため確認する。", "食材"),
        term("chocolat au lait", "ショコラ・オ・レ", "ミルクチョコレート", "乳成分を含むチョコレート。ダークより甘味が強く、乳固形分を含む。", "食材"),
        term("chocolat blanc", "ショコラ・ブラン", "ホワイトチョコレート", "カカオバター、砂糖、乳成分を主原料とし、カカオ固形分を含まない白いチョコレート。", "食材"),
        term("chocolat de couverture", "ショコラ・ド・クヴェルテュール", "クーベルチュールチョコレート", "カカオバターを多く含み流動性が高い製菓用チョコレート。コーティングや成形にはテンパリングが必要。", "食材"),
        term("beurre de cacao", "ブール・ド・カカオ", "カカオバター", "カカオ豆由来の油脂。チョコレートの流動性や口溶け、コーティングの調整に使う。", "食材"),
        term("gélatine", "ジェラティーヌ", "ゼラチン", "液体を冷却して固める凝固剤。feuilleは板、poudreは粉。強度と戻し方を確認する。", "食材"),
        term("gélatine en feuilles", "ジェラティーヌ・アン・フイユ", "板ゼラチン", "板状のゼラチン。冷水で戻して水気を切り、温かい液体へ溶かす。ブルーム強度を確認する。", "食材"),
        term("gélatine en poudre", "ジェラティーヌ・アン・プードル", "粉ゼラチン", "粉末状のゼラチン。指定量の冷水でふやかしてから溶かす。", "食材"),
        term("pectine NH", "ペクティーヌ・エヌアッシュ", "ペクチンNH", "再加熱で溶け、冷却で再び固まる熱可逆性ペクチン。ナパージュやフルーツのグラサージュに使う。", "食材"),
        term("agar-agar", "アガール・アガール", "寒天", "海藻由来の凝固剤。ゼラチンより高温で固まり、食感や溶解温度が異なる。", "食材"),
        term("gousse de vanille", "グース・ド・ヴァニーユ", "バニラビーンズ／バニラのさや", "バニラのさや。縦に割り、内部の種とさやを牛乳やクリームへ香り移しする。", "食材"),
        term("extrait de vanille", "エクストレ・ド・ヴァニーユ", "バニラエッセンス／バニラ抽出液", "バニラの香味成分を抽出した液体。天然抽出か香料主体か製品表示を確認する。", "食材"),
        term("échalote", "エシャロット", "エシャロット", "タマネギに近い香味野菜。ソース、ヴィネグレット、煮込みの香味に使う。", "食材"),
        term("poireau", "ポワロー", "ポロねぎ／西洋ねぎ／リーキ", "太い西洋ねぎ。白い部分を蒸し煮、スープ、香味野菜に使う。", "食材"),
        term("ail", "アイユ", "にんにく", "une gousse d’ailはにんにく一片。en chemiseは皮付きのまま。", "食材"),
        term("oignon", "オニョン", "玉ねぎ", "香味野菜の基本。émincerは薄切り、ciselerは細かく刻む。", "食材"),
        term("oignon nouveau", "オニョン・ヌーヴォー", "青ねぎ／葉玉ねぎ", "若採りの玉ねぎ。白い球部と緑の葉を生または加熱して使う。", "食材"),
        term("gingembre", "ジャンジャンブル", "しょうが", "生または乾燥した根茎を香味付けに使う。", "食材"),
        term("carotte", "キャロット", "にんじん", "香味野菜、付け合わせ、ピュレなどに用いる。", "食材"),
        term("céleri", "セルリ", "セロリ", "brancheは茎セロリ、raveは根セロリ。香味野菜としても使う。", "食材"),
        term("navet", "ナヴェ", "かぶ", "根は煮込み、グラッセ、ピュレなどに使う。", "食材"),
        term("radis", "ラディ", "ラディッシュ／大根類", "フランス語では各種大根類の総称。radis roseは赤いラディッシュ、radis blancは白大根。", "食材"),
        term("betterave", "ベトラーヴ", "ビーツ", "甘味と鮮やかな色を持つ根菜。ゆでる、ロースト、ピュレ、サラダなどに使う。", "食材"),
        term("fenouil", "フヌイユ", "フェンネル／ういきょう", "球茎、葉、種にアニス様の香りがあり、魚料理やサラダ、煮込みに使う。", "食材"),
        term("asperge", "アスペルジュ", "アスパラガス", "白・緑・紫などがあり、ゆでる、蒸す、ロースト、ソテーに使う。", "食材"),
        term("artichaut", "アルティショー", "アーティチョーク", "花蕾のがくと芯を食用にする。酸化しやすいため下処理後は酸を加えた水などで保護する。", "食材"),
        term("haricot vert", "アリコ・ヴェール", "さやいんげん", "若いさやを食べるいんげん。塩ゆで、ソテー、付け合わせに使う。", "食材"),
        term("petits pois", "プティ・ポワ", "グリーンピース", "若いえんどう豆。スープ、ピュレ、付け合わせに使う。", "食材"),
        term("bouquet garni", "ブーケ・ガルニ", "香草の束", "タイム、ローリエ、パセリの茎などを束ね、煮込みやフォンに香りを移して後で取り出す。", "食材"),
        term("fond", "フォン", "だし／ベースストック", "骨や香味野菜などから取る調理用のだし。fond blancとfond brunが代表的。", "食材"),
        term("bouillon", "ブイヨン", "煮出し汁", "肉、魚、野菜などを水で煮出した液体。スープまたは調理液として使う。", "食材"),
        term("fumet", "フュメ", "魚介などの香り高いだし", "主に魚の骨や香味野菜を短時間煮出す濃縮した調理液。", "食材"),
        term("eau", "オー", "水", "調理、加熱、希釈、生地作りなどに使う水。", "食材"),
        term("sel", "セル", "塩", "味付けや脱水、保存、生地の調整に使う。sel finは細塩、gros selは粗塩。", "食材"),
        term("poivre", "ポワーヴル", "こしょう", "粒または粉末で使う香辛料。noirは黒、blancは白。", "食材"),
        term("huile d’olive", "ユイル・ドリーヴ", "オリーブオイル", "オリーブの果実から採る油。加熱、マリネ、仕上げに使う。", "食材"),
        term("huile", "ユイル", "油", "加熱、揚げ物、乳化などに使う食用油の総称。", "食材"),
        term("vinaigre", "ヴィネーグル", "酢", "酸味付け、マリネ、ソースに使う。", "食材"),
        term("vin blanc", "ヴァン・ブラン", "白ワイン", "蒸し煮、ソース、デグラセなどに使う白ワイン。", "食材"),
        term("miel", "ミエル", "はちみつ", "甘味、つや、香り付けに使う。", "食材"),
        term("riz", "リ", "米", "主食、付け合わせ、リゾット、デザートなどに使う穀類。", "食材"),
        term("pomme de terre", "ポム・ド・テール", "じゃがいも", "付け合わせ、ピュレ、グラタン、揚げ物などに使う。", "食材"),
        term("patate douce", "パタット・ドゥース", "さつまいも", "甘味のあるいも。ロースト、ピュレ、菓子などに使う。", "食材"),
        term("tomate", "トマット", "トマト", "生食、ソース、煮込みなどに広く使う。", "食材"),
        term("concombre", "コンコンブル", "きゅうり", "生食、マリネ、冷製料理に使う。", "食材"),
        term("aubergine", "オベルジーヌ", "なす", "焼く、揚げる、煮込むなどの調理に使う。", "食材"),
        term("courgette", "クルジェット", "ズッキーニ", "ソテー、グリル、煮込みなどに使う。", "食材"),
        term("poivron", "ポワヴロン", "パプリカ／ピーマン", "甘味のあるとうがらし類。色によりrouge、jaune、vertなどと表す。", "食材"),
        term("chou", "シュー", "キャベツ", "生食、蒸し煮、スープ、付け合わせに使う。", "食材"),
        term("brocoli", "ブロコリ", "ブロッコリー", "房と茎をゆでる、蒸す、炒めるなどして使う。", "食材"),
        term("chou-fleur", "シュー・フルール", "カリフラワー", "ゆでる、グラタン、ピュレなどに使う。", "食材"),
        term("épinards", "エピナール", "ほうれん草", "複数形で使うことが多い葉野菜。ゆでる、炒める、ピュレなどにする。", "食材"),
        term("champignon de Paris", "シャンピニョン・ド・パリ", "マッシュルーム", "生食、ソテー、ソースなどに使う代表的な栽培きのこ。", "食材"),
        term("laitue", "レテュ", "レタス", "サラダのほか、蒸し煮やスープにも使う葉野菜。", "食材"),
        term("endive", "アンディーヴ", "チコリ／アンディーブ", "ほろ苦い葉菜。生食、蒸し煮、グラタンなどに使う。", "食材"),
        term("persil", "ペルスィ", "パセリ", "葉と茎を香味付けに使う。茎はブーケ・ガルニやフォンにも利用する。", "食材"),
        term("thym", "タン", "タイム", "加熱に強い香草。肉、魚、野菜、フォン、煮込みなどに使う。", "食材"),
        term("laurier", "ローリエ", "ローリエ／月桂樹の葉", "乾燥葉を煮込み、フォン、マリネなどの香り付けに使い、提供前に取り除く。", "食材"),
        term("romarin", "ロマラン", "ローズマリー", "樹脂系の強い香りを持つ香草。羊肉、鶏、じゃがいも、パンなどに使う。", "食材"),
        term("basilic", "バジリック", "バジル", "葉をソース、サラダ、仕上げに使う。長時間加熱では香りが弱まりやすい。", "食材"),
        term("estragon", "エストラゴン", "タラゴン／エストラゴン", "アニス様の香りがあり、鶏、魚、卵、ソース・ベアルネーズなどに使う。", "食材"),
        term("ciboulette", "シブレット", "チャイブ／西洋あさつき", "細い葉を刻み、卵料理、魚、クリーム、仕上げに使う。", "食材"),
        term("poulet", "プレ", "鶏肉", "若鶏。丸鶏または部位ごとにロースト、ソテー、煮込みなどに使う。", "食材"),
        term("cuisse de poulet", "キュイス・ド・プレ", "鶏もも肉", "鶏のもも部分。焼く、煮込む、揚げる調理に向く。", "食材"),
        term("blanc de poulet", "ブラン・ド・プレ", "鶏むね肉", "脂肪が少ない鶏の胸肉。加熱し過ぎによる乾燥に注意する。", "食材"),
        term("porc", "ポール", "豚肉", "部位によりロースト、ソテー、煮込みなどに使う。", "食材"),
        term("bœuf", "ブフ", "牛肉", "部位と用途に応じて焼く、煮る、ひき肉にする。", "食材"),
        term("veau", "ヴォー", "仔牛肉", "淡い色と繊細な味の仔牛肉。ソテー、ロースト、ブランケットなどに使う。", "食材"),
        term("agneau", "アニョー", "羊肉／仔羊肉", "一般に仔羊肉を指し、ローストや煮込みに使う。", "食材"),
        term("canard", "カナール", "鴨肉", "胸肉、もも肉、脂などをロースト、コンフィ、ソースに使う。", "食材"),
        term("dinde", "ダンド", "七面鳥", "脂肪が比較的少ない家禽。ロースト、詰め物、煮込みなどに使う。", "食材"),
        term("lapin", "ラパン", "うさぎ肉", "淡白な白身肉。マスタード煮、ロースト、テリーヌなどに使う。", "食材"),
        term("jambon", "ジャンボン", "ハム", "豚もも肉の加工品。生ハムはjambon cru、加熱ハムはjambon cuit。", "食材"),
        term("lardons", "ラルドン", "ベーコンの細切り", "豚ばら肉の塩漬けを小さな棒状に切ったもの。炒めて香味と脂を料理へ加える。", "食材"),
        term("saumon", "ソモン", "鮭／サーモン", "生、ポシェ、ソテー、燻製などで使う。", "食材"),
        term("cabillaud", "カビヨー", "たら", "白身魚。ポシェ、ロースト、ソテーなどに使う。", "食材"),
        term("daurade", "ドラード", "鯛／黒鯛類", "フランスで鯛類を指す名称。ロースト、グリル、ポシェなどに使う。", "食材"),
        term("bar", "バー", "すずき", "フランスで一般的な白身魚。丸ごとロースト、ポワレ、蒸し煮などに使う。", "食材"),
        term("sole", "ソル", "舌平目", "繊細な白身魚。ムニエル、蒸し煮、フィレ料理に使う。", "食材"),
        term("maquereau", "マクロ", "さば", "脂のある青魚。グリル、マリネ、燻製などに使う。", "食材"),
        term("thon", "トン", "まぐろ", "生食、グリル、コンフィ、缶詰などで使う大型魚。", "食材"),
        term("sardine", "サルディーヌ", "いわし", "脂のある小魚。グリル、マリネ、揚げ物、缶詰に使う。", "食材"),
        term("crevette", "クルヴェット", "えび", "殻付きまたはむき身で、ゆでる、焼く、ソースに使う。", "食材"),
        term("coquille Saint-Jacques", "コキーユ・サン・ジャック", "ほたて", "フランス料理で使われる帆立貝。貝柱をソテーやグラタンにする。", "食材"),
        term("moule", "ムール", "ムール貝", "蒸す、白ワイン煮、スープ、ソースなどに使う二枚貝。", "食材"),
        term("huître", "ユイトル", "牡蠣", "生食、ポシェ、グラタン、揚げ物などに使う。", "食材"),
        term("calmar", "カルマール", "いか", "胴、足、墨を料理に使う。encornetとも呼ばれる。", "食材"),
        term("poulpe", "プルプ", "たこ", "ゆでる、煮込む、グリル、マリネなどに使う。", "食材"),
        term("pomme", "ポム", "りんご", "生食、コンポート、タルト、ソースなどに使う。", "食材"),
        term("poire", "ポワール", "梨／洋梨", "生食、ポシェ、タルト、コンポートなどに使う。", "食材"),
        term("fraise", "フレーズ", "いちご", "生菓子、ソース、ジャムなどに使う。", "食材"),
        term("banane", "バナーヌ", "バナナ", "生食、焼き菓子、デザートに使う。", "食材"),
        term("citron", "シトロン", "レモン", "果汁と皮を酸味や香り付けに使う。", "食材"),
        term("orange", "オランジュ", "オレンジ", "果汁、果肉、皮を料理や菓子に使う。", "食材"),
        term("framboise", "フランボワーズ", "ラズベリー／木いちご", "生菓子、ピュレ、ソース、ジャムなどに使う。", "食材"),
        term("myrtille", "ミルティーユ", "ブルーベリー", "生菓子、タルト、ジャム、ソースなどに使う。", "食材"),
        term("abricot", "アブリコ", "あんず／アプリコット", "生、コンポート、ジャム、ナパージュ、焼き菓子に使う。", "食材"),
        term("pêche", "ペッシュ", "桃", "生食、ポシェ、コンポート、タルトなどに使う。", "食材"),
        term("mangue", "マング", "マンゴー", "生菓子、ムース、ピュレ、ソースなどに使う。", "食材"),
        term("ananas", "アナナ", "パイナップル", "生、ロースト、コンポート、菓子に使う。生果にはゼラチンを分解する酵素がある。", "食材"),
        term("raisin", "レザン", "ぶどう", "生食、ジュース、ソース、菓子、ワイン原料に使う。raisin secはレーズン。", "食材"),
        term("amande", "アマンド", "アーモンド", "粒、スライス、粉、ペーストなどで料理や製菓に使う。", "食材"),
        term("noisette", "ノワゼット", "ヘーゼルナッツ", "粒、粉、ペースト、プラリネとして製菓や料理に使う。", "食材"),
        term("pistache", "ピスターシュ", "ピスタチオ", "粒、刻み、ペーストとして菓子、シャルキュトリ、ソースに使う。", "食材"),
        term("noix", "ノワ", "くるみ", "生、ロースト、粉末、オイルなどで料理や菓子に使う。", "食材"),
        term("couper", "クペ", "切る", "包丁などで食材を切り分ける基本動作。", "調理技法"),
        term("ajouter", "アジュテ", "加える", "材料を別の材料や調理物に加える。", "調理技法"),
        term("verser", "ヴェルセ", "注ぐ", "液体や流動性のある材料を容器へ注ぐ。", "調理技法"),
        term("mélanger", "メランジェ", "混ぜる", "複数の材料を均一になるよう混ぜ合わせる。", "調理技法"),
        term("assaisonner", "アセゾネ", "味付けする", "塩、こしょう、香辛料などで味を調える。", "調理技法"),
        term("goûter", "グテ", "味見する", "仕上がりや調味を確認するため少量を味わう。", "調理技法"),
        term("chauffer", "ショフェ", "温める／加熱する", "材料や器具の温度を上げる。", "調理技法"),
        term("cuire", "キュイール", "火を通す", "熱を加えて食材を食べられる状態にする基本語。", "調理技法"),
        term("bouillir", "ブイイール", "沸騰させる", "液体を沸点まで加熱し、泡が連続して出る状態にする。", "調理技法"),
        term("frire", "フリール", "揚げる", "高温の油脂の中で食材を加熱する。", "調理技法"),
        term("griller", "グリエ", "グリルする", "直火や強い放射熱で表面を焼く。", "調理技法"),
        term("fondre", "フォンドル", "溶かす", "バターやチョコレートなどを加熱して液状にする。", "調理技法"),
        term("fouetter", "フエテ", "泡立て器で混ぜる", "泡立て器で勢いよく混ぜ、空気を含ませたり均一にする。", "調理技法"),
        term("pétrir", "ペトリール", "こねる", "パンや菓子の生地を押し、折り、のばしてまとめる。", "調理技法"),
        term("refroidir", "ルフロワディール", "冷ます", "調理物の温度を下げる。衛生上必要な場合は速やかに冷却する。", "調理技法"),
        term("abaisser", "アベセ", "生地をのばす", "麺棒やローラーで生地を目的の厚さまで薄くする。のばした生地はabaisse。", "調理技法"),
        term("blanchir", "ブランシール", "下ゆでする／白っぽく混ぜる", "料理では短時間ゆでて食感や味を整える。製菓では卵黄と砂糖を白っぽくなるまで混ぜる意味でも使う。", "調理技法"),
        term("saisir", "セジール", "表面を強火で焼き固める", "非常に熱い面や油に食材を当て、表面を短時間で加熱して焼き色を付ける。", "調理技法"),
        term("mijoter", "ミジョテ", "弱火でじっくり煮る", "沸騰を強く続けず、弱い火でゆっくり加熱して味をなじませる。", "調理技法"),
        term("déglacer", "デグラセ", "鍋底のうま味を溶かす", "焼いた鍋にワインや水などを加え、付着した焼き汁を溶かしてソースにする。", "調理技法"),
        term("réduire", "レデュイール", "煮詰める", "液体を加熱して水分を蒸発させ、量を減らして味や濃度を高める。", "調理技法"),
        term("émulsionner", "エミュルショネ", "乳化させる", "本来混ざりにくい油と水分を細かく分散させ、均一な状態にする。", "調理技法"),
        term("monter au beurre", "モンテ・オ・ブール", "バターで仕上げる", "火を弱めるか外し、冷たいバターを少量ずつ混ぜてソースに濃度とつやを付ける。", "調理技法"),
        term("lier", "リエ", "つなぐ／とろみを付ける", "でんぷん、卵黄、クリーム、バターなどでソースや液体に濃度を付ける。", "調理技法"),
        term("écumer", "エキュメ", "あくを取る", "液面に浮く泡や不純物を網じゃくしなどで除く。", "調理技法"),
        term("chinoiser", "シノワゼ", "シノワでこす", "円すい形の細かいこし器chinoisに通し、滑らかな液体にする。", "調理技法"),
        term("émincer", "エマンセ", "薄切りにする", "野菜や肉を薄く均一に切る。", "調理技法"),
        term("ciseler", "シズレ", "細かく刻む", "香草を細く切る、または玉ねぎ・エシャロットを細かなさいの目状に刻む。", "調理技法"),
        term("concasser", "コンカセ", "粗く砕く／刻む", "食材を粗めに砕く。tomates concasséesは皮と種を除いて粗く刻んだトマト。", "調理技法"),
        term("hacher", "アシェ", "みじん切りにする", "包丁や機械で細かく刻む。", "調理技法"),
        term("brunoise", "ブリュノワーズ", "小さいさいの目切り", "通常、数mm角の小さく均一な角切り。", "調理技法"),
        term("julienne", "ジュリエンヌ", "細いせん切り", "野菜などを細く均一な棒状に切る。", "調理技法"),
        term("braiser", "ブレゼ", "蒸し煮にする", "少量の液体とふたを用い、比較的ゆっくり火を通す。肉は先に焼き色を付けることが多い。", "調理技法"),
        term("pocher", "ポシェ", "沸騰させずにゆでる", "液体を静かな温度に保ち、卵、魚、果物などを穏やかに加熱する。", "調理技法"),
        term("rôtir", "ロティール", "ローストする", "主にオーブンや直火の乾いた熱で焼く。", "調理技法"),
        term("gratiner", "グラティネ", "表面に焼き色を付ける", "オーブンや上火で表面を香ばしく色付けする。", "調理技法"),
        term("flamber", "フランベ", "酒に点火する", "アルコールを加えて火を付け、香りを残しながらアルコール分を燃焼させる。", "調理技法"),
        term("mariner", "マリネ", "漬け込む", "香味、酸、油、酒などの液に食材を一定時間浸す。", "調理技法"),
        term("parer", "パレ", "不要部分を取り除き形を整える", "肉、魚、野菜などの筋、脂、皮、端などを除き、調理しやすい形に整える。", "調理技法"),
        term("dégraisser", "デグレセ", "脂を除く", "肉の余分な脂、またはフォンやソースの表面に浮いた脂を取り除く。", "調理技法"),
        term("désosser", "デゾセ", "骨を外す", "肉や家禽から、身をなるべく傷つけずに骨を取り除く。", "調理技法"),
        term("ébarber", "エバルベ", "ひれ・縁・はみ出しを除く", "魚のひれ、貝のひげ、成形品の余分な縁などを切り取って整える。", "調理技法"),
        term("écailler", "エカイエ", "うろこを取る", "うろこ取りや包丁の背で魚のうろこを除く。", "調理技法"),
        term("monder", "モンデ", "湯むきする", "トマトやアーモンドなどを短時間熱湯に入れ、皮を取り除く。émonderともいう。", "調理技法"),
        term("épépiner", "エペピネ", "種を取り除く", "果物や野菜の種と、必要に応じて種の周囲を除く。", "調理技法"),
        term("effeuiller", "エフイエ", "葉を摘む", "ハーブや葉野菜の葉を茎から外す。", "調理技法"),
        term("escaloper", "エスカロペ", "斜め薄切りにする", "肉、魚、きのこなどを斜めに、広い薄片になるよう切る。", "調理技法"),
        term("détailler", "デタイエ", "用途の形・大きさに切り分ける", "材料や生地を、指定された寸法や形に切り分ける。", "調理技法"),
        term("tailler", "タイエ", "規則的な形に切る", "材料を角切り、棒状、薄切りなど指定の形と寸法にそろえる。", "調理技法"),
        term("mirepoix", "ミルポワ", "香味野菜の角切り", "にんじん、玉ねぎなどを比較的大きめの不ぞろいな角切りにし、フォンや煮込みの香味に使う。", "調理技法"),
        term("macédoine", "マセドワーヌ", "さいの目切り", "野菜や果物を、ブリュノワーズより大きい均一な小角に切ったもの。", "調理技法"),
        term("paysanne", "ペイザンヌ", "薄い色紙切り", "野菜を薄い正方形、三角形、扇形など素材の形に合わせて切る。", "調理技法"),
        term("tourner", "トゥルネ", "面取りして形をそろえる", "野菜を小さな樽形などに削り、均一に火が入るよう形を整える。", "調理技法"),
        term("suer", "シュエ", "弱火で汗をかかせる", "食材を色付けず弱火で加熱し、水分を引き出して香りや甘味を出す。", "調理技法"),
        term("faire revenir", "フェール・ルヴニール", "油脂で炒めて色付ける", "材料を油脂で加熱し、表面に軽く焼き色を付けて香りを出す。", "調理技法"),
        term("étuver", "エテュヴェ", "ふたをして蒸し煮にする", "少量の水分や素材自身の水分を利用し、ふたをして弱火で加熱する。", "調理技法"),
        term("poêler", "ポワレ", "鍋で蒸し焼きにする", "本来はふた付きの厚手鍋で油脂と香味野菜を使い加熱する技法。現在はフライパン焼きの意味でも使われる。", "調理技法"),
        term("snacker", "スナケ", "強火で短時間焼く", "高温の鉄板やフライパンで表面を短時間香ばしく焼く。", "調理技法"),
        term("singer", "サンジェ", "小麦粉を振る", "炒めて色付けた肉や野菜に小麦粉を振り、加熱してから液体を加えて濃度を付ける。", "調理技法"),
        term("mouiller", "ムイエ", "液体を加える", "材料に水、フォン、ワインなどの液体を加え、煮るための水分を与える。", "調理技法"),
        term("clarifier", "クラリフィエ", "澄ませる／分ける", "液体の不純物を除いて澄ませること。卵では卵白と卵黄を分け、バターでは乳成分を分離する。", "調理技法"),
        term("dépouiller", "デプイエ", "煮ながら不純物を除く／皮を除く", "ソースなどを静かに煮ながら表面の膜や不純物を除く。食材の皮をはぐ意味もある。", "調理技法"),
        term("passer", "パセ／パッセ", "こす／裏ごしする", "調理物をシノワ、こし器、布などに通し、固形物や不純物を除く。フランス語の発音に近い表記は「パセ」だが、日本の厨房では作業名として「パッセ」とも呼ばれる。", "調理技法"),
        term("passer au chinois", "パセ・オ・シノワ／パッセ・オ・シノワ", "シノワでこす", "ソース、フォン、スープなどを円すい形のこし器シノワに通し、滑らかにする。押しつぶしながらこす場合はfoulerを伴う。", "調理技法"),
        term("passer au tamis", "パセ・オ・タミ／パッセ・オ・タミ", "ふるい・裏ごし器に通す", "粉をふるう、またはピュレなどを目の細かいtamisに通して均一で滑らかな状態にする。", "調理技法"),
        term("filtrer", "フィルトレ", "ろ過する", "布、紙、目の細かいこし器などを用い、液体から細かな固形物や不純物を取り除く。", "調理技法"),
        term("fouler", "フレ", "押しつぶしながらこす", "シノワなどの中の材料を押しつぶし、うま味や水分を十分に通す。", "調理技法"),
        term("habiller", "アビエ", "下処理する", "魚ならうろこ・ひれ・内臓などを除き、家禽なら羽や内臓を除いて、加熱できる状態まで整える一連の下処理。", "調理技法"),
        term("vider", "ヴィデ", "内臓を抜く", "魚、家禽、ジビエなどの腹部から内臓を取り除く。胆のうなどを破らないよう注意する。", "調理技法"),
        term("éplucher", "エプリュシェ", "皮をむく／不要部分を除く", "野菜や果物の皮、へた、根など食用にしない部分を取り除く。", "調理技法"),
        term("peler", "プレ", "皮をむく", "果物や野菜などの外皮を取り除く。éplucherより皮をむく動作そのものを指しやすい。", "調理技法"),
        term("lever les filets", "ルヴェ・レ・フィレ", "魚を三枚おろしにしてフィレを取る", "魚の骨格に沿って身を切り離し、左右のフィレを取る。", "調理技法"),
        term("désarêter", "デザレテ", "骨を抜く", "魚のフィレに残った小骨や血合い骨を骨抜きなどで取り除く。", "調理技法"),
        term("dénerver", "デネルヴェ", "筋を取り除く", "肉、レバー、フォワグラなどから太い筋、腱、血管を取り除く。", "調理技法"),
        term("châtrer", "シャトレ", "えびの背わたを取る", "えびやざりがにの尾から腸管を引き抜く下処理。", "調理技法"),
        term("laver", "ラヴェ", "洗う", "食材を水で洗い、土、血、汚れなどを取り除く。洗浄後は必要に応じて十分に水気を切る。", "調理技法"),
        term("égoutter", "エグテ", "水気を切る", "ざるやこし器に上げ、食材や調理物から余分な水分・油分を自然に落とす。", "調理技法"),
        term("essorer", "エソレ", "絞って水気を切る", "葉物、布、戻した材料などの水分を、手や器具で絞る、または回転させて除く。", "調理技法"),
        term("éponger", "エポンジェ", "水気を拭き取る", "布や紙で魚、肉、野菜などの表面の水分を押さえて取り除く。", "調理技法"),
        term("rafraîchir", "ラフレシール", "冷水に取って冷ます", "ゆでた食材を冷水や氷水へ移し、加熱の進行を止めて色や食感を保つ。", "調理技法"),
        term("ficeler", "フィスレ", "糸で縛る", "肉や家禽の形が加熱中に崩れないよう、調理用の糸で整えて縛る。", "調理技法"),
        term("brider", "ブリデ", "家禽を糸で縫い留める", "鶏などの脚や手羽を胴体に固定し、均一な火入れと美しい形を保つ。針と糸を使う方法もある。", "調理技法"),
        term("trousser", "トゥルセ", "家禽の形をまとめる", "家禽の脚や手羽を切れ目などへ差し込み、糸を使わず、または簡単な固定で形を整える。", "調理技法"),
        term("farcir", "ファルシール", "詰め物をする", "肉、魚、野菜、生地などの内部へfarce（詰め物）を詰める。", "調理技法"),
        term("barder", "バルデ", "脂身で覆う", "脂の少ない肉や家禽を薄い豚脂などで包み、加熱中の乾燥を防ぐ。", "調理技法"),
        term("larder", "ラルデ", "脂身を差し込む", "専用針などで赤身肉の内部へ細い脂身を差し込み、風味としっとり感を補う。", "調理技法"),
        term("contiser", "コンティゼ", "皮下に香味材料を差し込む", "肉、魚、家禽の皮の下へトリュフ、香草などの薄片を差し込み、香りと見た目を整える。", "調理技法"),
        term("découper", "デクペ", "切り分ける", "肉、家禽、魚、菓子などを提供や調理に適した部分・大きさへ切り分ける。", "調理技法"),
        term("tronçonner", "トロンソネ", "筒切り・ぶつ切りにする", "細長い魚、骨付き肉、野菜などを横方向へ一定の長さに切る。", "調理技法"),
        term("portionner", "ポルショネ", "一人前に分ける", "仕込み済みの食材や料理を、提供する一人前の重量・個数へ分割する。", "調理技法"),
        term("aplatir", "アプラティール", "たたいて平らにする", "肉や魚を肉たたきなどで均一な厚さにし、火通りや食感を整える。", "調理技法"),
        term("sauter", "ソテ", "強火で手早く焼く／炒める", "少量の油脂を使い、フライパンやソテ鍋で材料を比較的強火かつ短時間で加熱する。", "調理技法"),
        term("rissoler", "リソレ", "香ばしく焼き色を付ける", "油脂を使って食材の表面をむらなく褐色にし、香ばしさを出す。", "調理技法"),
        term("colorer", "コロレ", "焼き色を付ける", "食材を加熱して目的の色を付ける。焦がすbrûlerとは区別する。", "調理技法"),
        term("caraméliser", "カラメリゼ", "カラメル化する", "砂糖を褐色化させる、または食材表面の糖分を加熱して香ばしい色と風味を出す。", "調理技法"),
        term("confire", "コンフィール", "低温で煮る／糖・塩などで保存する", "油脂、砂糖、塩などの中で穏やかに加熱または漬け込み、保存性と独特の食感を与える。", "調理技法"),
        term("compoter", "コンポテ", "弱火で柔らかく煮崩す", "野菜や果物などを弱火でゆっくり加熱し、形が崩れて濃厚になるまで煮る。", "調理技法"),
        term("cuire à la vapeur", "キュイール・ア・ラ・ヴァプール", "蒸す", "蒸気を用い、食材を湯に直接触れさせずに加熱する。", "調理技法"),
        term("cuire à blanc", "キュイール・ア・ブラン", "空焼きする", "タルト生地などを、フィリングを入れず重石をして先に焼く。", "調理技法"),
        term("cuire à l’anglaise", "キュイール・ア・ラングレーズ", "塩ゆでする", "野菜などを多めの沸騰した塩水でゆで、必要に応じて氷水で急冷する。", "調理技法"),
        term("pincer", "パンセ", "骨・野菜を焼き付ける", "フォンなどの材料を鍋底や天板で褐色になるまで焼き、香ばしい風味と色を付ける。", "調理技法"),
        term("réserver", "レゼルヴェ", "取り置く", "後の工程で使うため、調理物を適切な温度・状態で一時的に置いておく。", "調理技法"),
        term("dresser", "ドレセ", "盛り付ける", "料理を皿や器に配置し、提供できる形に仕上げる。", "調理技法"),
        term("rectifier l’assaisonnement", "レクティフィエ・ラセゾヌマン", "味を調える", "仕上げ前に味見をし、塩、こしょう、酸味などを補って味を調整する。", "調理技法"),
        term("arroser", "アロゼ", "焼き汁をかける", "加熱中の肉や魚に溶けた油脂や焼き汁を繰り返しかけ、乾燥を防ぎ風味を与える。", "調理技法"),
        term("glacer", "グラセ", "つやを付ける", "煮汁を煮詰めて野菜などをつやよく覆う、または菓子の表面を糖衣などで覆う。", "調理技法"),
        term("paner à l’anglaise", "パネ・ア・ラングレーズ", "小麦粉・卵・パン粉を付ける", "材料に小麦粉、溶き卵、パン粉の順で衣を付ける。", "調理技法"),
        term("foncer", "フォンセ", "型に生地を敷き込む", "のばした生地を型の底と側面に沿わせ、密着させる。", "製菓"),
        term("chemiser", "シュミゼ", "型の内側を覆う", "型離れや成形のため、バター、小麦粉、紙、チョコレートなどで型の内側を覆う。", "製菓"),
        term("fraiser", "フレゼ", "生地を台にこすりつけてまとめる", "手の付け根で生地を押しのばし、粉と油脂を均一にまとめる。練り過ぎない。", "製菓"),
        term("crémer", "クレメ", "バターをクリーム状にする", "やわらかいバターを滑らかに練り、砂糖などと混ぜる。", "製菓"),
        term("foisonner", "フォワゾネ", "空気を抱き込ませる", "泡立てによって体積を増やし、軽い状態にする。", "製菓"),
        term("macaroner", "マカロネ", "マカロン生地を練り合わせる", "メレンゲと粉類を混ぜ、生地につやと適切な流動性を出す。", "製菓"),
        term("incorporer", "アンコルポレ", "混ぜ込む", "別の材料を全体へ均一に加える。泡を保つ場合はやさしく混ぜる。", "製菓"),
        term("tamiser", "タミゼ", "ふるう", "粉類をふるいに通し、だまや異物を除いて空気を含ませる。", "製菓"),
        term("napper", "ナペ", "覆う／濃度が付くまで加熱する", "ソースで表面を覆うこと。crème anglaiseではへらの背を薄く覆う濃度を指す。", "製菓"),
        term("imbiber", "アンビベ", "シロップを染み込ませる", "スポンジなどにシロップや酒を含ませ、風味と湿り気を与える。", "製菓"),
        term("dorer", "ドレ", "つや出しを塗る／焼き色を付ける", "卵液などを塗って焼成後につやと色を付ける。", "製菓"),
        term("sabler", "サブレ", "粉と油脂をそぼろ状にする", "粉に冷たいバターをすり込み、砂のようなさらさらした状態にする。", "製菓"),
        term("dessécher", "デセシェ", "加熱して水分を飛ばす", "シュー生地などを鍋で練りながら加熱し、余分な水分を除く。", "製菓"),
        term("détendre", "デタンドル", "やわらかくのばす", "固い生地やクリームに液体ややわらかい材料を少量加え、混ぜやすい濃度にする。", "製菓"),
        term("serrer", "セレ", "泡を締める", "泡立てた卵白に砂糖を加えてさらに泡立て、きめを細かく安定させる。", "製菓"),
        term("ruban", "リュバン", "リボン状に落ちる状態", "卵と砂糖などを泡立て、生地を落とすと跡が帯状にしばらく残る状態。", "製菓"),
        term("chiqueter", "シクテ", "生地の縁に刻み目を付ける", "折り込み生地などの縁へ包丁で細かな切り込みを入れ、飾りと膨らみを整える。", "製菓"),
        term("piquer", "ピケ", "生地に穴を開ける", "焼成時の浮き上がりを防ぐため、フォークやピケローラーで生地に小穴を開ける。", "製菓"),
        term("beurrer", "ブーレ", "型にバターを塗る", "型離れをよくし、焼き色や風味を与えるため、型の内側へバターを均一に塗る。", "製菓"),
        term("fariner", "ファリネ", "粉を振る", "作業台や型、生地、食材などへ薄く小麦粉を振り、付着を防ぐ。", "製菓"),
        term("mouler", "ムレ", "型に入れて成形する", "生地、クリーム、チョコレートなどを型へ入れ、型の形に整える。", "製菓"),
        term("démouler", "デムレ", "型から外す", "固める・冷やす・焼く工程を終えた製品を、崩さないよう型から取り出す。", "製菓"),
        term("coucher", "クシェ", "絞り出す", "絞り袋を使ってシュー生地、メレンゲ、ビスキュイなどを天板へ一定の形に絞る。", "製菓"),
        term("pocher à la douille", "ポシェ・ア・ラ・ドゥイユ", "口金で絞る", "絞り袋と口金を使い、クリームや生地を目的の形・量に絞り出す。", "製菓"),
        term("abricoter", "アブリコテ", "あんずジャムを塗る", "温めて裏ごししたあんずジャムなどを菓子の表面へ塗り、乾燥を防いでつやを出す。", "製菓"),
        term("corser", "コルセ", "生地にこしを出す", "生地をこねてグルテンを形成し、弾力や強さを出す。練り込み生地では必要以上に行わない。", "製菓"),
        term("corner", "コルネ", "カードでボウルを払う", "corne（カード）を使い、ボウルに付いた生地やクリームを集めてきれいに取る。", "製菓"),
        term("marbrer", "マルブレ", "大理石模様を付ける", "色や濃度の異なる生地、フォンダン、チョコレートなどを完全に混ぜず模様を作る。", "製菓"),
        term("tempérer", "タンペレ", "温度調整する", "チョコレートの結晶を安定させるため温度を上げ下げするなど、材料を目的の温度に整える。", "製菓"),
        term("tabler", "タブレ", "大理石台で温度を下げる", "溶かしたチョコレートの一部を大理石台で動かしながら冷却し、テンパリングする方法。", "製菓"),
        term("pâte sucrée", "パート・シュクレ", "甘いタルト生地", "バター、砂糖、卵、粉類で作る、甘く崩れやすいタルト用生地。", "製菓"),
        term("pâte brisée", "パート・ブリゼ", "練り込みパイ生地", "甘味を抑えたもろい生地。タルトやキッシュに使う。", "製菓"),
        term("pâte feuilletée", "パート・フイユテ", "折り込みパイ生地", "生地とバターの層を折り重ね、蒸気で層状に膨らませる。", "製菓"),
        term("bouler", "ブレ", "丸める", "パン生地の表面を張らせながら丸く整え、内部のガスと生地組織を均一にする。", "製パン"),
        term("façonner", "ファソネ", "最終成形する", "分割・休ませを終えたパン生地を、焼き上がりに合わせた最終形へ整える。", "製パン"),
        term("pointer", "ポワンテ", "一次発酵させる", "ミキシング後から分割までの生地発酵。温度と時間を管理して香りと生地構造を作る。", "製パン"),
        term("dégazer", "デガゼ", "ガスを抜く", "発酵で生じた大きな気泡を押して抜き、温度と気泡を均一にする。", "製パン"),
        term("rabattre", "ラバトル", "パンチする／折りたたむ", "発酵途中の生地を押す、または折りたたみ、ガスと温度を整えて生地へ力を与える。", "製パン"),
        term("apprêt", "アプレ", "最終発酵", "成形後から焼成直前までの発酵。製品のボリュームと内相を左右する。", "製パン"),
        term("grigner", "グリニェ", "クープを入れる", "焼成直前のパン生地表面へ刃で切り込みを入れ、膨張方向と見た目を整える。", "製パン"),
        term("fleurer", "フルレ", "作業台に薄く粉を振る", "パン生地が作業台や布へ付着しないよう、必要最小限の粉を薄く振る。", "製パン"),
        term("tourer", "トゥレ", "折り込みをする", "生地と油脂をのばして折る操作を繰り返し、クロワッサンや折り込み生地の層を作る。", "製パン"),
        term("scarifier", "スカリフィエ", "表面に切り込みを入れる", "パンや食材の表面へ刃物で切れ目を入れる。パンではgrignerと近い意味で使う。", "製パン"),
        term("appareil", "アパレイユ", "合わせた生地・混合物", "複数材料を混ぜた、焼成や仕上げ前の調製物。日本語の家電という意味ではない。", "状態・器具"),
        term("mise en place", "ミザン・プラス", "段取り／事前準備", "営業や調理開始前に、材料、器具、ソース、切り物などを必要な状態と位置へ準備すること。", "状態・器具"),
        term("garniture", "ガルニチュール", "付け合わせ／具材", "主材料に添える野菜などの付け合わせ、またはスープ・ソースなどに加える具材。", "状態・器具"),
        term("jus", "ジュ", "肉汁／焼き汁／果汁", "肉や貝などの調理で出るうま味を含む汁、または果物・野菜の汁。", "状態・器具"),
        term("roux", "ルー", "小麦粉とバターを炒めたつなぎ", "通常は小麦粉とバターを加熱して作り、ソースやスープの濃度付けに使う。加熱度で白・金・褐色に分かれる。", "状態・器具"),
        term("duxelles", "デュクセル", "きのこのみじん切り炒め", "きのこやエシャロットなどを細かく刻んで炒め、水分を飛ばした詰め物・付け合わせのベース。", "状態・器具"),
        term("zeste", "ゼスト", "柑橘類の表皮", "レモンやオレンジなどの香りのある色付き表皮。苦い白い部分をなるべく含めず使う。", "状態・器具"),
        term("bain-marie", "バン・マリ", "湯せん", "容器を湯に当て、直接火を当てず穏やかに加熱または保温する。", "状態・器具"),
        term("cul-de-poule", "キュル・ド・プール", "丸底ボウル", "底が丸い金属製ボウル。混ぜる、泡立てる作業に使う。", "状態・器具"),
        term("chinois", "シノワ", "円すい形のこし器", "ソースやスープを細かくこすための円すい形ストレーナー。", "状態・器具"),
        term("étamine", "エタミーヌ", "こし布", "フォンやソースなどを細かく澄んだ状態にこすために使う目の細かい布。", "状態・器具"),
        term("passoire", "パソワール", "ざる／水切り", "液体をこす、または食材の水気を切るための穴や網目がある器具。", "状態・器具"),
        term("tamis", "タミ", "ふるい／裏ごし器", "粉の粒をそろえる、またはピュレなどを滑らかに裏ごしするための網状の器具。", "状態・器具"),
        term("maryse", "マリーズ", "ゴムべら", "ボウルの曲面に沿って生地やクリームを集め、混ぜ合わせるための柔軟なへら。", "状態・器具"),
        term("écumoire", "エキュモワール", "穴じゃくし／網じゃくし", "液体からあくや食材をすくい取るため、穴または網が付いた器具。", "状態・器具"),
        term("marmite", "マルミット", "深鍋／寸胴鍋", "フォン、ブイヨン、煮込みなどに用いる深い大型の鍋。", "状態・器具"),
        term("sauteuse", "ソトゥーズ", "ソテ鍋", "底が広く、比較的浅い両手または片手鍋。ソテ、煮詰め、ソース作りなどに使う。", "状態・器具"),
        term("poche à douille", "ポッシュ・ア・ドゥイユ", "絞り袋", "口金を付け、クリームや生地を一定の形・量に絞るための袋。", "状態・器具"),
        term("douille", "ドゥイユ", "口金", "絞り袋の先に付け、丸、星、花びらなど絞り出す形を決める器具。", "状態・器具"),
        term("nappant", "ナパン", "へらを覆う濃度", "ソースやクリームがへらの背を薄く覆い、指で線を引くと跡が残る程度の濃度。", "状態・器具"),
        term("bleu", "ブルー", "ごくレアの焼き加減", "牛肉などの中心がほぼ生で冷たさを残し、表面だけを短時間焼いた状態。", "状態・器具"),
        term("saignant", "セニャン", "レアの焼き加減", "肉の中心が赤く、肉汁を多く残した焼き加減。", "状態・器具"),
        term("rosé", "ロゼ", "ばら色の焼き加減", "仔羊、鴨などの中心が淡いばら色に仕上がった状態。", "状態・器具"),
        term("bien cuit", "ビヤン・キュイ", "よく焼いた状態", "肉の中心まで十分に加熱された焼き加減。", "状態・器具"),
        term("beurre pommade", "ブール・ポマード", "ポマード状バター", "室温でやわらかくし、軟膏のように滑らかな状態のバター。溶かしバターではない。", "状態・器具"),
        term("beurre noisette", "ブール・ノワゼット", "焦がしバター", "バターを加熱し、乳固形分をヘーゼルナッツ色にして香ばしさを出した状態。", "状態・器具"),
        term("à point", "ア・ポワン", "適度な焼き加減", "肉の焼き加減では一般にミディアム相当。文脈により「ちょうどよい状態」も表す。", "状態・器具")
    ]

    static func matches(_ query: String, limit: Int = 20) -> [FrenchCulinaryTerm] {
        matches(query, in: allTerms, limit: limit)
    }

    static func matches(
        _ query: String,
        in candidates: [FrenchCulinaryTerm],
        limit: Int = 20
    ) -> [FrenchCulinaryTerm] {
        let key = normalize(query)
        guard !key.isEmpty else { return Array(candidates.prefix(limit)) }
        return Array(candidates.filter {
            normalize($0.french).contains(key) || normalize($0.reading).contains(key) ||
                normalize($0.japanese).contains(key) || normalize($0.meaning).contains(key)
        }.prefix(limit))
    }

    static func exactMatch(_ query: String) -> FrenchCulinaryTerm? {
        let key = normalize(query)
        return allTerms.first { term in
            normalize(term.french) == key || normalize(term.reading) == key ||
                japaneseNames(for: term).contains { normalize($0) == key }
        }
    }

    static func translatedIngredientName(_ name: String, language: String) -> String {
        guard let term = exactMatch(name), term.category == "食材" else { return name }
        switch language {
        case "日本語": return primaryJapaneseName(for: term)
        case "Français": return term.french
        default: return name
        }
    }

    static func primaryJapaneseName(for term: FrenchCulinaryTerm) -> String {
        japaneseNames(for: term).first ?? term.japanese
    }

    static func equivalentIngredientNames(for name: String) -> [String] {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let term = exactMatch(trimmed),
              term.category == "食材" else { return trimmed.isEmpty ? [] : [trimmed] }

        var names = [trimmed, term.french, term.reading] + japaneseNames(for: term)
        var seen = Set<String>()
        return names.filter { candidate in
            let key = normalize(candidate)
            guard !key.isEmpty, !seen.contains(key) else { return false }
            seen.insert(key)
            return true
        }
    }

    private static func japaneseNames(for term: FrenchCulinaryTerm) -> [String] {
        term.japanese
            .components(separatedBy: CharacterSet(charactersIn: "／/"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    static func termsFound(in text: String, limit: Int = 3) -> [FrenchCulinaryTerm] {
        let key = normalize(text)
        guard !key.isEmpty else { return [] }
        return Array(allTerms.filter { key.contains(normalize($0.french)) }
            .sorted { $0.french.count > $1.french.count }
            .prefix(limit))
    }

    private static func normalize(_ text: String) -> String {
        let katakana = text.applyingTransform(.hiraganaToKatakana, reverse: false) ?? text
        return katakana.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: Locale(identifier: "fr_FR"))
            .replacingOccurrences(of: #"[\s’'\-・ー／/]"#, with: "", options: .regularExpression)
    }

    private static func term(
        _ french: String,
        _ reading: String,
        _ japanese: String,
        _ meaning: String,
        _ category: String
    ) -> FrenchCulinaryTerm {
        FrenchCulinaryTerm(
            french: french,
            reading: reading,
            japanese: japanese,
            meaning: meaning,
            category: category,
            source: "辻調理師専門学校・東京ベルエポック製菓調理専門学校の公開資料、Académie française・CNRTL・Académie du Goût・CAP Cuisine資料を基に要約"
        )
    }
}

struct FrenchGlossaryView: View {
    @State private var query = ""
    @State private var category = "すべて"
    @State private var customTerms = UserCulinaryDictionary.load()
    @State private var showingAddTerm = false

    private var availableTerms: [FrenchCulinaryTerm] {
        FrenchCulinaryGlossary.terms + customTerms.map(\.glossaryTerm)
    }

    private var filteredTerms: [FrenchCulinaryTerm] {
        let matches = query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? availableTerms
            : FrenchCulinaryGlossary.matches(query, in: availableTerms, limit: availableTerms.count)
        return category == "すべて" ? matches : matches.filter { $0.category == category }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("種類", selection: $category) {
                        ForEach(FrenchCulinaryGlossary.categories, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)
                }

                ForEach(filteredTerms) { term in
                    NavigationLink {
                        List {
                            Section {
                                Text(term.french).font(.largeTitle.bold())
                                Text(term.reading).foregroundStyle(.secondary)
                                Text(term.japanese).font(.title2.weight(.semibold)).foregroundStyle(.orange)
                            }
                            Section("意味・使い方") { Text(term.meaning) }
                            Section("分類") { Text(term.category) }
                            Section("情報源") { Text(term.source).font(.footnote).foregroundStyle(.secondary) }
                        }
                        .navigationTitle(term.french)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(term.french).font(.headline)
                            Text("\(term.japanese)・\(term.reading)").font(.subheadline).foregroundStyle(.secondary)
                            Text(term.meaning).font(.caption).lineLimit(2)
                        }
                    }
                    .swipeActions {
                        if term.source == "ユーザー追加" {
                            Button("削除", role: .destructive) {
                                customTerms.removeAll { $0.french == term.french && $0.category == term.category }
                                UserCulinaryDictionary.save(customTerms)
                            }
                        }
                    }
                }
            }
            .navigationTitle("フランス語辞典")
            .searchable(text: $query, prompt: "仏語・日本語・読み方で検索")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingAddTerm = true } label: {
                        Label("辞書に追加", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTerm) {
                AddFrenchCulinaryTermView { term in
                    customTerms.removeAll {
                        $0.french.compare(term.french, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
                    }
                    customTerms.append(term)
                    UserCulinaryDictionary.save(customTerms)
                }
            }
            .overlay {
                if filteredTerms.isEmpty {
                    ContentUnavailableView("用語が見つかりません", systemImage: "text.magnifyingglass")
                }
            }
        }
    }
}

struct AddFrenchCulinaryTermView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var french = ""
    @State private var reading = ""
    @State private var japanese = ""
    @State private var meaning = ""
    @State private var category = "調理技法"
    let onSave: (UserFrenchCulinaryTerm) -> Void

    private var canSave: Bool {
        !french.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !japanese.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("用語") {
                    TextField("フランス語", text: $french)
                        .textInputAutocapitalization(.never)
                    TextField("日本語での読み方", text: $reading)
                    TextField("日本語の意味", text: $japanese)
                    Picker("分類", selection: $category) {
                        ForEach(FrenchCulinaryGlossary.categories.filter { $0 != "すべて" }, id: \.self) {
                            Text($0).tag($0)
                        }
                    }
                }
                Section("説明") {
                    TextField("意味・使い方を入力", text: $meaning, axis: .vertical)
                        .lineLimit(3...7)
                }
            }
            .navigationTitle("辞書に追加")
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        onSave(UserFrenchCulinaryTerm(
                            french: french.trimmingCharacters(in: .whitespacesAndNewlines),
                            reading: reading.trimmingCharacters(in: .whitespacesAndNewlines),
                            japanese: japanese.trimmingCharacters(in: .whitespacesAndNewlines),
                            meaning: meaning.trimmingCharacters(in: .whitespacesAndNewlines),
                            category: category
                        ))
                        dismiss()
                    }
                    .disabled(!canSave)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完了") { dismissKeyboard() }
                }
            }
        }
    }
}
