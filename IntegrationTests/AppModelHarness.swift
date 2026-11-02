import Foundation
import LexcopeCore

/// Runs against the real UI model and filesystem, without an iOS simulator.
@main
struct AppModelHarness {
    @MainActor static func main() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("lexcope-integration-\(UUID().uuidString)")
        let store = StateStore(fileURL: directory.appendingPathComponent("state.json"))
        let model = AppModel(store: store)
        precondition(model.state?.words.count == 60, "Cold start must create the bundled library")
        precondition(model.queue.wordIDs.isEmpty, "No deck selected initially")
        model.toggleDeck("ngsl-starter")
        precondition(model.queue.new.count == 20)
        let word = model.state!.words[model.queue.wordIDs.first!]!
        let initial = model.state!

        // Force a real disk write failure without changing the model or deleting files.
        let preserved = directory.appendingPathExtension("preserved")
        try FileManager.default.moveItem(at: directory, to: preserved)
        try Data("write blocker".utf8).write(to: directory)
        precondition(!model.rate(word, .known), "A failed write must reject a rating")
        precondition(model.state == initial, "UI must not advance on failed save")
        precondition(model.undoReceipt == nil)
        precondition(model.errorMessage != nil)
        try FileManager.default.moveItem(at: directory, to: directory.appendingPathExtension("blocker"))
        try FileManager.default.moveItem(at: preserved, to: directory)

        precondition(model.rate(word, .known))
        let restored = AppModel(store: store)
        precondition(restored.state?.progress[word.id]?.reviewCount == 1)
        precondition(restored.queue.studiedNewToday == 1)
        precondition(model.undo() == word.id)
        precondition(model.state == initial, "Undo restores progress and daily credit")

        let vocabulary = try VocabularyImport.parse(Data("term,meaning\nremember,替代释义\nresilient,有韧性的".utf8), format: .csv, fallbackTitle: "我的词集")
        precondition(model.importVocabulary(vocabulary))
        precondition(model.state?.words["remember"]?.meaning == initial.words["remember"]?.meaning)
        precondition(model.state?.decks.count == 5)
        let diskState = try store.load()
        precondition(diskState == model.state)
        print("PASS: cold start, selection, save-failure rollback, rating, restart, quota, undo, import, persistence")
    }
}
