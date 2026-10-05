import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @ObservedObject var store: RecipeStore
    @State private var exportDocument = RecipeArchiveDocument()
    @State private var showingExporter = false
    @State private var showingImporter = false
    @State private var csvDocument = DataExportDocument(contentType: .commaSeparatedText)
    @State private var showingCSVExporter = false
    @State private var resultMessage = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        exportBackup()
                    } label: {
                        Label("レシピを書き出す", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        showingImporter = true
                    } label: {
                        Label("バックアップを読み込む", systemImage: "square.and.arrow.down")
                    }

                    Button {
                        csvDocument = DataExportDocument(data: store.csvData(), contentType: .commaSeparatedText)
                        showingCSVExporter = true
                    } label: {
                        Label("材料一覧をCSVで保存", systemImage: "tablecells")
                    }

                    NavigationLink {
                        RecentlyDeletedView(store: store)
                    } label: {
                        Label("最近削除した項目", systemImage: "trash")
                    }
                } header: {
                    Text("バックアップ・機種変更")
                } footer: {
                    Text("書き出したJSONファイルをiCloud Driveなどに保存すると、別のiPhoneでも読み込めます。既存レシピは残したまま統合されます。")
                }

                Section("プライバシー") {
                    NavigationLink("プライバシーポリシー") {
                        PrivacyPolicyView()
                    }
                    Label("レシピは端末内に保存", systemImage: "lock.shield")
                        .foregroundStyle(.secondary)
                }

                Section("アプリについて") {
                    LabeledContent("アプリ名", value: "My Recipi")
                    LabeledContent("バージョン", value: "1.0")
                }
            }
            .navigationTitle("設定")
            .fileExporter(
                isPresented: $showingExporter,
                document: exportDocument,
                contentType: .json,
                defaultFilename: "MyRecipi-Backup"
            ) { result in
                switch result {
                case .success:
                    resultMessage = NSLocalizedString("バックアップを書き出しました。", comment: "")
                case .failure:
                    resultMessage = NSLocalizedString("書き出しに失敗しました。", comment: "")
                }
            }
            .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.json]) { result in
                importBackup(result)
            }
            .fileExporter(
                isPresented: $showingCSVExporter,
                document: csvDocument,
                contentType: .commaSeparatedText,
                defaultFilename: "MyRecipi-Materials"
            ) { _ in }
            .alert("My Recipi", isPresented: Binding(
                get: { !resultMessage.isEmpty },
                set: { if !$0 { resultMessage = "" } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(resultMessage)
            }
        }
    }

    private func exportBackup() {
        do {
            exportDocument = RecipeArchiveDocument(data: try store.backupData())
            showingExporter = true
        } catch {
            resultMessage = NSLocalizedString("書き出しに失敗しました。", comment: "")
        }
    }

    private func importBackup(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            guard url.startAccessingSecurityScopedResource() else {
                throw CocoaError(.fileReadNoPermission)
            }
            defer { url.stopAccessingSecurityScopedResource() }
            let count = try store.importBackup(Data(contentsOf: url))
            resultMessage = String(
                format: NSLocalizedString("%d件のレシピを読み込みました。", comment: ""),
                count
            )
        } catch {
            resultMessage = NSLocalizedString("バックアップを読み込めませんでした。", comment: "")
        }
    }
}

private struct PrivacyPolicyView: View {
    var body: some View {
        List {
            Section {
                Text("My Recipiは、登録したレシピをこの端末内に保存します。開発者のサーバーへレシピや写真を送信しません。")
                Text("写真の文字認識はAppleの端末内機能を使用します。選択・撮影した写真は、文字認識後にアプリ内へ保存されません。")
                Text("完成写真として追加した画像は、この端末内に保存されます。")
                Text("バックアップファイルは、利用者が選んだ保存先にのみ書き出されます。")
            }
        }
        .navigationTitle("プライバシーポリシー")
        .navigationBarTitleDisplayMode(.inline)
    }
}
