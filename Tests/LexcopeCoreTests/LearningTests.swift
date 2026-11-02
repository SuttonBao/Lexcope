import Foundation
import Testing
@testable import LexcopeCore

struct LearningTests {
    var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Australia/Sydney")!
        return c
    }
    func date(_ value: String) -> Date { ISO8601DateFormatter().date(from: value)! }
    func fixture() -> AppState {
        var state = AppState()
        for term in ["one", "two", "three"] { state.words[term] = Word(term: term, meaning: "词") }
        state.decks = [Deck(id: "a", title: "A", wordIDs: ["one", "two", "three"]),
                       Deck(id: "b", title: "B", wordIDs: ["one"])]
        state.activeDeckIDs = ["a", "b"]
        return state
    }

    @Test func knownProgressesThroughIntervalsAndCapsAtThirtyDays() {
        var now = date("2026-11-03T03:00:00Z")
        var progress: WordProgress?
        for days in [1, 2, 4, 7, 15, 30, 30] {
            let next = Scheduler.review(progress, rating: .known, at: now, calendar: calendar)
            #expect(calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: next.dueAt).day == days)
            #expect(next.stage <= 6)
            progress = next; now = next.dueAt
        }
        #expect(progress?.reviewCount == 7)
    }

    @Test func unknownAndFuzzyRequireShortRelearning() {
        let now = date("2026-11-03T03:00:00Z")
        let previous = WordProgress(stage: 4, dueAt: now, firstStudiedAt: now, lastReviewedAt: now)
        let unknown = Scheduler.review(previous, rating: .unknown, at: now)
        #expect(unknown.stage == 0 && unknown.lapses == 1)
        #expect(unknown.dueAt == now.addingTimeInterval(300))
        let fuzzy = Scheduler.review(previous, rating: .fuzzy, at: now)
        #expect(fuzzy.stage == 3 && fuzzy.dueAt == now.addingTimeInterval(600))
        #expect(Scheduler.review(nil, rating: .fuzzy, at: now).stage == 0)
    }

    @Test func nextNaturalDaySurvivesDaylightSaving() {
        let beforeDST = date("2026-10-03T02:00:00Z") // Sydney noon before spring DST.
        let next = Scheduler.review(nil, rating: .known, at: beforeDST, calendar: calendar)
        let midnight = calendar.startOfDay(for: beforeDST)
        #expect(calendar.component(.day, from: next.dueAt) == 4)
        #expect(calendar.component(.hour, from: next.dueAt) == 0)
        let dstDay = date("2026-10-04T02:00:00Z")
        let after = Scheduler.review(nil, rating: .known, at: dstDay, calendar: calendar)
        #expect(after.dueAt.timeIntervalSince(calendar.startOfDay(for: dstDay)) == 23 * 3600)
        #expect(next.dueAt > midnight)
    }

    @Test func queuesDueFirstDeduplicatesAndPersistsDailyBudget() throws {
        var state = fixture(); state.settings.dailyNewLimit = 1
        let now = date("2026-11-03T03:00:00Z")
        #expect(Learning.queue(in: state, at: now).wordIDs == ["one"])
        try Learning.rate("one", rating: .unknown, in: &state, at: now)
        let restored = try JSONDecoder().decode(AppState.self, from: JSONEncoder().encode(state))
        #expect(Learning.queue(in: restored, at: now).wordIDs.isEmpty)
        #expect(Learning.queue(in: state, at: now.addingTimeInterval(300)).due == ["one"])
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        #expect(Learning.queue(in: state, at: tomorrow, calendar: calendar).wordIDs == ["one", "two"])
        #expect(Learning.selectedWordIDs(in: state).count == 3)
    }

    @Test func rejectsEarlyReviewAndCanUndoWithoutErasingSettings() throws {
        var state = fixture(); let now = date("2026-11-03T03:00:00Z")
        let receipt = try Learning.rate("one", rating: .known, in: &state, at: now)
        #expect(throws: LearningError.self) { try Learning.rate("one", rating: .known, in: &state, at: now) }
        state.settings.dailyNewLimit = 10
        try Learning.undo(receipt, in: &state)
        #expect(state.progress["one"] == nil && state.events.isEmpty)
        #expect(state.settings.dailyNewLimit == 10)
        #expect(Learning.queue(in: state, at: now).studiedNewToday == 0)
    }

    @Test func cannotUndoOutOfOrderAndRestoresPreviousReview() throws {
        var state = fixture(); let now = date("2026-11-03T03:00:00Z")
        let first = try Learning.rate("one", rating: .unknown, in: &state, at: now)
        let previous = state.progress["one"]
        let second = try Learning.rate("one", rating: .known, in: &state, at: now.addingTimeInterval(300))
        #expect(throws: LearningError.self) { try Learning.undo(first, in: &state) }
        try Learning.undo(second, in: &state)
        #expect(state.progress["one"] == previous)
        #expect(state.events.count == 1)
    }

    @Test func noNewCardsWhenLimitIsZeroButReviewsRemain() throws {
        var state = fixture(); let now = date("2026-11-03T03:00:00Z")
        try Learning.rate("one", rating: .unknown, in: &state, at: now)
        state.settings.dailyNewLimit = 0
        #expect(Learning.queue(in: state, at: now.addingTimeInterval(600)).wordIDs == ["one"])
        state.activeDeckIDs = []
        #expect(Learning.queue(in: state, at: now.addingTimeInterval(600)).wordIDs.isEmpty)
    }

    @Test func streakAllowsYesterdayUntilTodayIsStudied() throws {
        var state = fixture(); let now = date("2026-11-03T03:00:00Z")
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        try Learning.rate("one", rating: .known, in: &state, at: yesterday, calendar: calendar)
        #expect(Learning.streak(in: state, at: now, calendar: calendar) == 1)
        try Learning.rate("two", rating: .known, in: &state, at: now, calendar: calendar)
        #expect(Learning.streak(in: state, at: now, calendar: calendar) == 2)
        #expect(Learning.reviewedToday(in: state, at: now, calendar: calendar) == 1)
    }

    @Test func gesturesRejectTapsUpwardAndDiagonalDrags() {
        #expect(SwipeDirection.classify(x: 100, y: 10) == .right)
        #expect(SwipeDirection.classify(x: -100, y: 10) == .left)
        #expect(SwipeDirection.classify(x: 10, y: 100) == .down)
        #expect(SwipeDirection.classify(x: 10, y: -100) == nil)
        #expect(SwipeDirection.classify(x: 79, y: 0) == nil)
        #expect(SwipeDirection.classify(x: 90, y: 90) == nil)
    }
}
