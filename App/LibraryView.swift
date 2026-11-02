import SwiftUI
import UniformTypeIdentifiers
import LexcopeCore

struct LibraryView: View {
    @EnvironmentObject private var model: AppModel
    @State private var isImporting = false
    @State private var isParsing = false
    @State private var pending: ImportPreview?
    @State private var importError: String?
    @State private var previewError: String?
    @State private var showImportHelp = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("可同时选择多个词集。重叠单词共享进度，优先复习到期的词。")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                if let state = model.state {
                    Section("内置词集") {
                        ForEach(state.decks.filter(\.isBuiltIn)) { deck in deckRow(deck, state: state) }
                    }
                    Section("我的词集") {
                        let personal = state.decks.filter { !$0.isBuiltIn }
                        if personal.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("把想记的词放在一起").font(.headline)
                                Text("从“文件”导入 CSV 或 JSON。每条至少提供英文和中文释义。")
                                    .font(.subheadline).foregroundStyle(.secondary)
                            }.padding(.vertical, 8)
                        }
                        ForEach(personal) { deck in deckRow(deck, state: state) }
                        Button { isImporting = true } label: {
                            Label(isParsing ? "正在校验词集…" : "导入词集", systemImage: "square.and.arrow.down")
                        }.disabled(isParsing)
                        Button("查看导入格式") { showImportHelp = true }
                    }
                    Section("关于内置内容") {
                        Text("60 个起始词条，含生活词、短语及学术备考选词。PTE / IELTS 选词不是官方或完整考试词库。")
                            .font(.footnote).foregroundStyle(.secondary)
                        NavigationLink("来源与授权") { SourcesView() }
                    }
                }
            }
            .navigationTitle("词集")
            .toolbar { ToolbarItem(placement: .primaryAction) {
                Button { isImporting = true } label: { Label("导入词集", systemImage: "plus") }.disabled(isParsing)
            } }
            .fileImporter(isPresented: $isImporting, allowedContentTypes: [.commaSeparatedText, .json], allowsMultipleSelection: false) { result in
                switch result {
                case .success(let urls): if let url = urls.first { parse(url) }
                case .failure(let error): importError = error.localizedDescription
                }
            }
            .sheet(item: $pending) { preview in importPreview(preview) }
            .sheet(isPresented: $showImportHelp) { ImportHelpView() }
            .alert("无法导入", isPresented: Binding(get: { importError != nil }, set: { if !$0 { importError = nil } })) {
                Button("知道了", role: .cancel) { importError = nil }
            } message: { Text(importError ?? "") }
        }
    }

    private func deckRow(_ deck: Deck, state: AppState) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Button { model.toggleDeck(deck.id) } label: {
                Image(systemName: state.activeDeckIDs.contains(deck.id) ? "checkmark.circle.fill" : "circle")
                    .font(.title2).frame(minWidth: 44, minHeight: 44)
            }.buttonStyle(.borderless).accessibilityIdentifier("select-deck-\(deck.id)")
                .accessibilityLabel("\(state.activeDeckIDs.contains(deck.id) ? "取消选择" : "选择")\(deck.title)")
                .accessibilityAddTraits(state.activeDeckIDs.contains(deck.id) ? .isSelected : [])
            NavigationLink {
                DeckDetailView(deck: deck)
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    Text(deck.title).font(.headline)
                    Text(deck.subtitle).font(.caption).foregroundStyle(.secondary)
                    let learned = deck.wordIDs.filter { state.progress[$0] != nil }.count
                    Text("已学 \(learned) / \(deck.wordIDs.count)").font(.caption).foregroundStyle(.secondary)
                }.padding(.vertical, 8)
            }
        }
    }

    private func parse(_ url: URL) {
        isParsing = true
        Task {
            do {
                let vocabulary = try await Task.detached(priority: .userInitiated) {
                    let access = url.startAccessingSecurityScopedResource()
                    defer { if access { url.stopAccessingSecurityScopedResource() } }
                    let handle = try FileHandle(forReadingFrom: url)
                    defer { try? handle.close() }
                    let data = try handle.read(upToCount: VocabularyImport.maximumBytes + 1) ?? Data()
                    guard let format = ImportFormat(rawValue: url.pathExtension.lowercased()) else {
                        throw ImportError.message("请选择 .csv 或 .json 文件。")
                    }
                    return try VocabularyImport.parse(data, format: format, fallbackTitle: url.deletingPathExtension().lastPathComponent)
                }.value
                pending = ImportPreview(vocabulary: vocabulary)
            } catch { importError = error.localizedDescription }
            isParsing = false
        }
    }

    private func importPreview(_ preview: ImportPreview) -> some View {
        NavigationStack {
            List {
                Section(preview.vocabulary.title) {
                    Text("已校验 \(preview.vocabulary.words.count) 个词条")
                    let reused = preview.vocabulary.words.filter { model.state?.words[$0.id] != nil }.count
                    Text("其中 \(reused) 个已有单词将保留原有释义和学习进度。")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Section("预览前 5 个词条") {
                    ForEach(Array(preview.vocabulary.words.prefix(5))) { word in
                        VStack(alignment: .leading, spacing: 8) { Text(word.term).font(.headline); Text(word.meaning).foregroundStyle(.secondary) }
                    }
                }
            }
            .navigationTitle("导入预览").inlineTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { pending = nil } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("导入并选用") {
                        if model.importVocabulary(preview.vocabulary) { pending = nil }
                        else {
                            previewError = model.errorMessage ?? "请检查设备存储空间后重试。"
                            model.errorMessage = nil
                        }
                    }
                }
            }
            .alert("导入未保存", isPresented: Binding(get: { previewError != nil }, set: { if !$0 { previewError = nil } })) {
                Button("知道了", role: .cancel) { previewError = nil }
            } message: { Text(previewError ?? "") }
        }
    }
}

private struct ImportPreview: Identifiable {
    let id = UUID()
    let vocabulary: VocabularyImport
}

private struct DeckDetailView: View {
    let deck: Deck
    @EnvironmentObject private var model: AppModel
    @State private var selectedWord: Word?
    @State private var query = ""
    var body: some View {
        List {
            Section { Text(deck.source).font(.footnote).foregroundStyle(.secondary) }
            Section {
                ForEach(deck.wordIDs.compactMap { model.state?.words[$0] }.filter {
                    query.isEmpty || $0.term.localizedCaseInsensitiveContains(query) || $0.meaning.localizedCaseInsensitiveContains(query)
                }) { word in
                    Button { selectedWord = word } label: {
                        HStack {
                            Text(word.term).foregroundStyle(.primary)
                            Spacer()
                            if let progress = model.state?.progress[word.id] {
                                Text(progress.dueAt, style: .date).font(.caption).foregroundStyle(.secondary)
                            }
                        }.padding(.vertical, 8)
                    }
                }
            }
        }
        .searchable(text: $query, prompt: "搜索单词或中文")
        .navigationTitle(deck.title).inlineTitle()
        .sheet(item: $selectedWord) { WordDetailView(word: $0) }
    }
}

struct SourcesView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("有出处，也有边界").font(.title2.weight(.semibold))
                Text(BuiltInLibrary.acknowledgments()).textSelection(.enabled)
                Link("NGSL 官方词表", destination: URL(string: "https://www.newgeneralservicelist.com/new-general-service-list")!)
                Link("NAWL 官方词表", destination: URL(string: "https://www.newgeneralservicelist.com/new-academic-word-list")!)
                Link("CC BY-SA 4.0 授权", destination: URL(string: "https://creativecommons.org/licenses/by-sa/4.0/")!)
            }.padding(24).frame(maxWidth: 680).frame(maxWidth: .infinity)
        }.navigationTitle("来源与授权").inlineTitle()
    }
}

private struct ImportHelpView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            List {
                Section("CSV") {
                    Text("UTF-8 编码，首行字段名至少含 term、meaning。可选 ipa、definition、example、example_chinese、etymology、collocations、family。")
                    Text("term,ipa,meaning\nremember,/rɪˈmembə/,记住").font(.system(.footnote, design: .monospaced)).textSelection(.enabled)
                    Text("含逗号或换行的字段请用双引号包围，字段内双引号写两次。搭配和词族以 | 分隔。")
                }
                Section("JSON") {
                    Text(#"{"title":"我的词集","words":[{"term":"remember","meaning":"记住","ipa":"/rɪˈmembə/"}]}"#)
                        .font(.system(.footnote, design: .monospaced)).textSelection(.enabled)
                    Text("可选 definition、etymology、collocations 和 family；examples 是包含 english、chinese 的对象数组。")
                }
                Section("导入规则") {
                    Text("每次导入 1 至 5000 词，文件不超过 2 MB。词集内重复词需先合并。已有词保留原释义和进度，导入词集将自动选中。")
                    Text("音标可留空，仍能点击播放读音。缺失的释义详情不会自动生成。")
                }
            }.navigationTitle("导入格式").inlineTitle()
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { dismiss() } } }
        }
    }
}
