import SwiftUI

// 最初に表示する画面
// 下のタブはここでまとめている
struct ContentView: View {
    // どの画面でも同じレシピデータを使う
    @StateObject private var store = RecipeStore()

    var body: some View {
        TabView {
            // レシピ一覧
            RecipeLibraryView(store: store)
                .tabItem { Label("レシピ", systemImage: "book.pages") }

            // 食材から検索
            IngredientSearchView(store: store)
                .tabItem { Label("食材から探す", systemImage: "carrot") }

            // フランス語辞典
            FrenchGlossaryView()
                .tabItem { Label("仏語辞典", systemImage: "character.book.closed") }

            // 買い物リストやタイマー
            KitchenHubView(store: store)
                .tabItem { Label("キッチン", systemImage: "list.clipboard") }

            // バックアップなどの設定
            SettingsView(store: store)
                .tabItem { Label("設定", systemImage: "gearshape") }
        }
        .tint(.orange)
        // どの画面でも、入力欄の外を押すとキーボードを閉じます。
        .background(KeyboardDismissController())
    }
}
