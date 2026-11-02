import Foundation

public enum ImportFormat: String, Sendable { case csv, json }

public struct VocabularyImport: Sendable {
    public let title: String
    public let words: [Word]
    public static let maximumBytes = 2 * 1024 * 1024
    public static let maximumWords = 5_000

    public static func parse(_ data: Data, format: ImportFormat, fallbackTitle: String) throws -> Self {
        guard data.count <= maximumBytes else { throw ImportError.message("文件不能超过 2 MB。") }
        guard var text = String(data: data, encoding: .utf8) else {
            throw ImportError.message("请将文件保存为 UTF-8 编码后重试。")
        }
        if text.first == "\u{FEFF}" { text.removeFirst() }
        let title: String
        let entries: [ImportEntry]
        switch format {
        case .json:
            let payload: ImportPayload
            do { payload = try JSONDecoder().decode(ImportPayload.self, from: Data(text.utf8)) }
            catch { throw ImportError.message("JSON 格式不正确。请使用包含 title 和 words 的对象，并检查字段类型。") }
            title = payload.title ?? fallbackTitle
            entries = payload.words
        case .csv:
            let rows = try CSV.parse(text)
            guard let first = rows.first else { throw ImportError.message("文件为空。") }
            let header = first.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            let allowed: Set<String> = ["term", "ipa", "meaning", "definition", "example", "example_chinese", "etymology", "collocations", "family"]
            guard header.contains("term"), header.contains("meaning"),
                  Set(header).count == header.count, Set(header).isSubset(of: allowed) else {
                throw ImportError.message("CSV 首行必须包含 term、meaning；表头不可重复或包含未知字段。")
            }
            entries = try rows.dropFirst().enumerated().map { index, row in
                guard row.count == header.count else { throw ImportError.message("第 \(index + 2) 条 CSV 记录的列数与表头不一致。") }
                let fields = Dictionary(uniqueKeysWithValues: zip(header, row))
                return ImportEntry(term: fields["term"]!, ipa: fields["ipa"], meaning: fields["meaning"]!,
                    definition: fields["definition"], examples: fields["example"].flatMap {
                        $0.isEmpty ? nil : [Example(english: $0, chinese: fields["example_chinese"] ?? "")]
                    }, etymology: fields["etymology"],
                    collocations: fields["collocations"]?.components(separatedBy: "|"),
                    family: fields["family"]?.components(separatedBy: "|"))
            }
            title = fallbackTitle
        }
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty, cleanTitle.count <= 100 else { throw ImportError.message("词集名称须为 1 至 100 个字符。") }
        guard !entries.isEmpty, entries.count <= maximumWords else { throw ImportError.message("一个词集须包含 1 至 5000 个词条。") }
        var seen: Set<String> = []
        let words: [Word] = try entries.enumerated().map { index, item in
            let term = item.term.trimmingCharacters(in: .whitespacesAndNewlines)
            let meaning = item.meaning.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !term.isEmpty, term.count <= 120, !meaning.isEmpty, meaning.count <= 2000,
                  !term.contains(where: { $0.isNewline || $0.asciiValue.map { $0 < 32 } == true }) else {
                throw ImportError.message("第 \(index + 1) 个词条的 term 或 meaning 为空、过长或包含控制字符。")
            }
            guard seen.insert(Word.key(term)).inserted else { throw ImportError.message("第 \(index + 1) 个词条“\(term)”重复，请合并后重试。") }
            let detailStrings = [item.ipa ?? "", item.definition ?? "", item.etymology ?? ""]
                + (item.examples ?? []).flatMap { [$0.english, $0.chinese] }
                + (item.collocations ?? []) + (item.family ?? [])
            guard detailStrings.allSatisfy({ $0.count <= 10_000 }),
                  (item.examples?.count ?? 0) <= 30,
                  (item.collocations?.count ?? 0) <= 100, (item.family?.count ?? 0) <= 100 else {
                throw ImportError.message("第 \(index + 1) 个词条的详情过长。")
            }
            return Word(term: term, ipa: item.ipa ?? "", meaning: meaning,
                        definition: item.definition ?? "", examples: item.examples ?? [],
                        etymology: item.etymology, collocations: clean(item.collocations), family: clean(item.family))
        }
        return Self(title: cleanTitle, words: words)
    }

    /// Shared spelling retains existing definitions and progress; the preview reports reuse.
    @discardableResult
    public func apply(to state: inout AppState) -> Deck {
        for word in words where state.words[word.id] == nil { state.words[word.id] = word }
        let deck = Deck(title: title, subtitle: "个人词集", wordIDs: words.map(\.id))
        state.decks.append(deck)
        state.activeDeckIDs.insert(deck.id)
        return deck
    }

    private static func clean(_ items: [String]?) -> [String] {
        (items ?? []).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    }
}

private struct ImportPayload: Decodable { var title: String?; var words: [ImportEntry] }
private struct ImportEntry: Decodable {
    var term: String
    var ipa: String?
    var meaning: String
    var definition: String?
    var examples: [Example]?
    var etymology: String?
    var collocations: [String]?
    var family: [String]?
}

public enum ImportError: Error, LocalizedError {
    case message(String)
    public var errorDescription: String? { if case .message(let text) = self { text } else { nil } }
}

private enum CSV {
    enum Mode { case start, plain, quoted, afterQuote }
    static func parse(_ input: String) throws -> [[String]] {
        let input = input.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
        var mode = Mode.start
        var rows: [[String]] = [], row: [String] = [], field = ""
        func finishField() { row.append(field); field = ""; mode = .start }
        func finishRow() {
            finishField()
            if !row.allSatisfy({ $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) { rows.append(row) }
            row = []
        }
        for character in input {
            switch mode {
            case .start:
                switch character {
                case "\"": mode = .quoted
                case ",": finishField()
                case "\n": finishRow()
                default: field.append(character); mode = .plain
                }
            case .plain:
                switch character {
                case ",": finishField()
                case "\n": finishRow()
                case "\"": throw ImportError.message("第 \(rows.count + 1) 条 CSV 记录的引号位置不正确。")
                default: field.append(character)
                }
            case .quoted:
                if character == "\"" { mode = .afterQuote } else { field.append(character) }
            case .afterQuote:
                switch character {
                case "\"": field.append("\""); mode = .quoted
                case ",": finishField()
                case "\n": finishRow()
                default: throw ImportError.message("第 \(rows.count + 1) 条 CSV 记录的闭合引号后存在多余字符。")
                }
            }
            guard rows.count <= VocabularyImport.maximumWords + 1 else { throw ImportError.message("词条数量超过 5000。") }
        }
        guard mode != .quoted else { throw ImportError.message("CSV 存在未闭合的引号。") }
        if !field.isEmpty || !row.isEmpty || mode == .afterQuote { finishRow() }
        return rows
    }
}
