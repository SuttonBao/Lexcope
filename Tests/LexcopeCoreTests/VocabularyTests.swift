import Foundation
import Testing
@testable import LexcopeCore

struct VocabularyTests {
    func csv(_ string: String) throws -> VocabularyImport {
        try VocabularyImport.parse(Data(string.utf8), format: .csv, fallbackTitle: "导入词集")
    }
    @Test func builtInsHaveCompleteFieldsAndValidSharedMembership() throws {
        let state = try BuiltInLibrary.initialState()
        #expect(state.words.count == 60 && state.decks.count == 4)
        #expect(state.activeDeckIDs.isEmpty)
        #expect(state.words.values.allSatisfy { !$0.ipa.isEmpty && !$0.definition.isEmpty && !$0.examples.isEmpty && !$0.collocations.isEmpty && !$0.family.isEmpty })
        let pte = Set(state.decks[1].wordIDs), ielts = Set(state.decks[2].wordIDs)
        #expect(pte.intersection(ielts).count == 8)
    }
    @Test func csvSupportsBOMCommaQuotesMultilineAndCRLF() throws {
        let result = try csv("\u{FEFF}term,meaning,example,collocations\r\nword,\"词,单词\",\"He said \"\"word\"\".\nAgain.\",a|b\r\n")
        #expect(result.words[0].meaning == "词,单词")
        #expect(result.words[0].examples[0].english == "He said \"word\".\nAgain.")
        #expect(result.words[0].collocations == ["a", "b"])
    }
    @Test func csvRejectsMalformedFieldsAndDuplicateWords() {
        for text in ["term,meaning\na,", "term,meaning\na,一\nA,二", "term,meaning\n\"a,b",
                     "term,meaning\na,\"b\"extra", "term,term\na,b", "term,meaning\na,b,c",
                     "term,meaning,unknown\na,b,c", "term,meaning\na\"b,c"] {
            #expect(throws: ImportError.self) { try csv(text) }
        }
    }
    @Test func jsonAllowsMissingOptionalFieldsAndRequiresMeaning() throws {
        let valid = Data(#"{"title":"test","words":[{"term":"word","meaning":"单词"}]}"#.utf8)
        let result = try VocabularyImport.parse(valid, format: .json, fallbackTitle: "fallback")
        #expect(result.title == "test" && result.words[0].ipa.isEmpty)
        for text in [#"{"words":[{"term":"word"}]}"#, #"{"words":[]}"#, #"{"words":[{"term":7,"meaning":"x"}]}"#] {
            #expect(throws: ImportError.self) { try VocabularyImport.parse(Data(text.utf8), format: .json, fallbackTitle: "test") }
        }
    }
    @Test func largeFilesAndInvalidEncodingAreRejected() {
        #expect(throws: ImportError.self) { try VocabularyImport.parse(Data(repeating: 65, count: VocabularyImport.maximumBytes + 1), format: .csv, fallbackTitle: "test") }
        #expect(throws: ImportError.self) { try VocabularyImport.parse(Data([0xff]), format: .csv, fallbackTitle: "test") }
        #expect(throws: ImportError.self) { try csv("term,meaning\n" + (0...5000).map { "w\($0),词" }.joined(separator: "\n")) }
    }
    @Test func applyingImportReusesWordAndDoesNotOverwriteDefinitionOrProgress() throws {
        var state = try BuiltInLibrary.initialState()
        let original = state.words["remember"]!
        let now = Date()
        state.progress["remember"] = Scheduler.review(nil, rating: .known, at: now)
        let progress = state.progress["remember"]
        let result = try csv("term,meaning\nremember,替代释义\nnew word,新词")
        let deck = result.apply(to: &state)
        #expect(state.words["remember"] == original)
        #expect(state.progress["remember"] == progress)
        #expect(state.activeDeckIDs.contains(deck.id))
        #expect(state.words["new word"] != nil)
        try state.validate()
    }
}
