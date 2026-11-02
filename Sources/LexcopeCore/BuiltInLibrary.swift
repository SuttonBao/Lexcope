import Foundation

public enum BuiltInLibrary {
    public static func initialState() throws -> AppState {
        guard let url = Bundle.module.url(forResource: "vocabulary", withExtension: "json") else {
            throw StateError.invalidData
        }
        let content = try JSONDecoder().decode(Content.self, from: Data(contentsOf: url))
        var state = AppState()
        for word in content.words {
            guard state.words[word.id] == nil else { throw StateError.invalidData }
            state.words[word.id] = word
        }
        state.decks = content.decks
        // User chooses a deck before any cards are introduced.
        try state.validate()
        return state
    }
    public static func acknowledgments() -> String {
        """
        生活选词摘选自 NGSL 1.2；学术选词摘选自 NAWL 1.2。
        Browne, C., Culligan, B., & Phillips, J. (2013).
        https://www.newgeneralservicelist.com
        原始词表及本应用的选词、学习内容采用 CC BY-SA 4.0：
        https://creativecommons.org/licenses/by-sa/4.0/
        释义、中文、音标和例句为 Lexcope 编写的起始内容，并非原作者的词典释义。词源未核实时留空。
        PTE / IELTS 词集为学术备考入门选词，不是官方词表或完整考试词库。
        """
    }
    private struct Content: Decodable { var words: [Word]; var decks: [Deck] }
}
