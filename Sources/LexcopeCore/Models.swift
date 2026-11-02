import Foundation

public struct Example: Codable, Equatable, Sendable {
    public var english: String
    public var chinese: String
    public init(english: String, chinese: String = "") {
        self.english = english; self.chinese = chinese
    }
}

public struct Word: Codable, Equatable, Identifiable, Sendable {
    public var id: String { Self.key(term) }
    public var term: String
    public var ipa: String
    public var meaning: String
    public var definition: String
    public var examples: [Example]
    public var etymology: String?
    public var collocations: [String]
    public var family: [String]
    public var source: String

    public static func key(_ term: String) -> String {
        term.trimmingCharacters(in: .whitespacesAndNewlines)
            .precomposedStringWithCanonicalMapping.lowercased()
    }

    public init(term: String, ipa: String = "", meaning: String, definition: String = "",
                examples: [Example] = [], etymology: String? = nil,
                collocations: [String] = [], family: [String] = [], source: String = "用户导入") {
        self.term = term.trimmingCharacters(in: .whitespacesAndNewlines)
        self.ipa = ipa; self.meaning = meaning; self.definition = definition
        self.examples = examples; self.etymology = etymology
        self.collocations = collocations; self.family = family; self.source = source
    }
}

public struct Deck: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var title: String
    public var subtitle: String
    public var wordIDs: [String]
    public var source: String
    public var isBuiltIn: Bool
    public init(id: String = UUID().uuidString, title: String, subtitle: String = "",
                wordIDs: [String], source: String = "用户导入", isBuiltIn: Bool = false) {
        self.id = id; self.title = title; self.subtitle = subtitle
        self.wordIDs = wordIDs; self.source = source; self.isBuiltIn = isBuiltIn
    }
}

public enum Rating: String, Codable, CaseIterable, Sendable {
    case unknown, fuzzy, known
    public var title: String {
        switch self { case .unknown: "不认识"; case .fuzzy: "模糊"; case .known: "认识" }
    }
}

public struct WordProgress: Codable, Equatable, Sendable {
    public var stage: Int
    public var dueAt: Date
    public var firstStudiedAt: Date
    public var lastReviewedAt: Date
    public var reviewCount: Int
    public var lapses: Int
    public init(stage: Int = 0, dueAt: Date, firstStudiedAt: Date,
                lastReviewedAt: Date, reviewCount: Int = 0, lapses: Int = 0) {
        self.stage = stage; self.dueAt = dueAt; self.firstStudiedAt = firstStudiedAt
        self.lastReviewedAt = lastReviewedAt; self.reviewCount = reviewCount; self.lapses = lapses
    }
}

public struct ReviewEvent: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var wordID: String
    public var rating: Rating
    public var date: Date
    public var isFirstStudy: Bool
}

public struct Settings: Codable, Equatable, Sendable {
    public var dailyNewLimit: Int = 20
    public var voiceLanguage: String = "en-GB"
    public var reminderEnabled: Bool = false
    public var reminderHour: Int = 20
    public var reminderMinute: Int = 0
    public init() {}
}

public struct AppState: Codable, Equatable, Sendable {
    public var schemaVersion: Int = 1
    public var words: [String: Word] = [:]
    public var decks: [Deck] = []
    public var activeDeckIDs: Set<String> = []
    public var progress: [String: WordProgress] = [:]
    public var events: [ReviewEvent] = []
    public var settings = Settings()
    public init() {}

    public func validate() throws {
        guard schemaVersion == 1 else { throw StateError.unsupportedVersion }
        let deckIDs = Set(decks.map(\.id))
        guard deckIDs.count == decks.count, activeDeckIDs.isSubset(of: deckIDs),
              (0...200).contains(settings.dailyNewLimit),
              ["en-GB", "en-US"].contains(settings.voiceLanguage),
              (0...23).contains(settings.reminderHour), (0...59).contains(settings.reminderMinute),
              words.allSatisfy({ key, word in key == word.id && !key.isEmpty && !word.meaning.isEmpty }),
              decks.allSatisfy({ !$0.title.isEmpty && Set($0.wordIDs).count == $0.wordIDs.count
                  && $0.wordIDs.allSatisfy { words[$0] != nil } }),
              progress.allSatisfy({ key, value in words[key] != nil && (0...6).contains(value.stage)
                  && value.reviewCount >= 0 && value.lapses >= 0 }),
              Set(events.map(\.id)).count == events.count,
              events.allSatisfy({ words[$0.wordID] != nil && progress[$0.wordID] != nil })
        else { throw StateError.invalidData }
    }
}

public enum StateError: Error, LocalizedError {
    case unsupportedVersion, invalidData
    public var errorDescription: String? {
        switch self {
        case .unsupportedVersion: "此学习记录来自其他版本，请更新应用后重试。原文件已保留。"
        case .invalidData: "学习记录不完整，无法载入。原文件已保留，请重试或恢复备份。"
        }
    }
}
