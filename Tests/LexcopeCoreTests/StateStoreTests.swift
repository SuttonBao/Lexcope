import Foundation
import Testing
@testable import LexcopeCore

struct StateStoreTests {
    @Test func testSaveAndLoadRoundTrip() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = StateStore(fileURL: url)
        #expect(try store.load() == nil)
        var state = AppState()
        let word = Word(term: "Remember", ipa: "/rɪˈmembə/", meaning: "记住")
        state.words[word.id] = word
        state.decks = [Deck(id: "daily", title: "日常", wordIDs: [word.id])]
        state.activeDeckIDs = ["daily"]
        try store.save(state)
        #expect(try store.load() == state)
        try FileManager.default.removeItem(at: url)
    }

    @Test func testCorruptionIsNotOverwritten() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let bad = Data("broken".utf8)
        try bad.write(to: url)
        #expect(throws: (any Error).self) { try StateStore(fileURL: url).load() }
        #expect(try Data(contentsOf: url) == bad)
        try FileManager.default.removeItem(at: url)
    }

    @Test func testInvalidWritePreservesExistingState() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = StateStore(fileURL: url)
        try store.save(AppState())
        var invalid = AppState(); invalid.schemaVersion = 99
        #expect(throws: (any Error).self) { try store.save(invalid) }
        #expect(try store.load() == AppState())
        invalid = AppState(); invalid.activeDeckIDs = ["missing"]
        #expect(throws: (any Error).self) { try invalid.validate() }
        try FileManager.default.removeItem(at: url)
    }
}
