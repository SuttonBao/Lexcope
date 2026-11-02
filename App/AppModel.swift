import Foundation
import Combine
import LexcopeCore

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var state: AppState?
    @Published private(set) var now = Date()
    @Published private(set) var undoReceipt: ReviewReceipt?
    @Published var errorMessage: String?
    let store: StateStore

    init(store: StateStore? = nil) {
        var directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Lexcope", isDirectory: true)
        #if DEBUG
        if let session = ProcessInfo.processInfo.environment["LEXCOPE_UI_TEST_SESSION"], UUID(uuidString: session) != nil {
            directory = directory.appendingPathComponent("UITests/\(session)", isDirectory: true)
        }
        #endif
        self.store = store ?? StateStore(fileURL: directory.appendingPathComponent("state.json"))
        load()
    }

    var queue: DailyQueue {
        Learning.queue(in: state ?? AppState(), at: now)
    }

    func load() {
        do {
            if let saved = try store.load() { state = saved }
            else {
                let initial = try BuiltInLibrary.initialState()
                try store.save(initial)
                state = initial
            }
            errorMessage = nil
            refresh()
        } catch { errorMessage = "无法载入学习记录：\(error.localizedDescription)" }
    }

    func refresh() { now = Date() }

    @discardableResult
    func change(_ edit: (inout AppState) throws -> Void) -> Bool {
        guard var updated = state else { return false }
        do {
            try edit(&updated)
            try store.save(updated)
            state = updated
            refresh()
            return true
        } catch {
            errorMessage = "未保存此次操作：\(error.localizedDescription)"
            return false
        }
    }

    @discardableResult
    func rate(_ word: Word, _ rating: Rating) -> Bool {
        let date = Date()
        var receipt: ReviewReceipt?
        let saved = change { receipt = try Learning.rate(word.id, rating: rating, in: &$0, at: date) }
        if saved { undoReceipt = receipt }
        return saved
    }

    func undo() -> String? {
        guard let receipt = undoReceipt else { return nil }
        guard change({ try Learning.undo(receipt, in: &$0) }) else { return nil }
        undoReceipt = nil
        return receipt.wordID
    }

    func toggleDeck(_ id: String) {
        change {
            if $0.activeDeckIDs.contains(id) { $0.activeDeckIDs.remove(id) }
            else { $0.activeDeckIDs.insert(id) }
        }
    }

    func updateSettings(_ settings: Settings) -> Bool {
        change { $0.settings = settings }
    }

    @discardableResult
    func importVocabulary(_ vocabulary: VocabularyImport) -> Bool {
        change { vocabulary.apply(to: &$0) }
    }
}
