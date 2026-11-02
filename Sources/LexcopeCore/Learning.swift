import Foundation

public enum Scheduler {
    public static let dayIntervals = [1, 2, 4, 7, 15, 30]

    public static func review(_ previous: WordProgress?, rating: Rating, at now: Date,
                              calendar: Calendar = .current) -> WordProgress {
        var result = previous ?? WordProgress(dueAt: now, firstStudiedAt: now, lastReviewedAt: now)
        result.lastReviewedAt = now
        result.reviewCount += 1
        switch rating {
        case .known:
            let index = min(max(result.stage, 0), dayIntervals.count - 1)
            // Natural days, not multiples of 86,400 seconds (DST safe).
            result.dueAt = calendar.date(byAdding: .day, value: dayIntervals[index],
                                         to: calendar.startOfDay(for: now))!
            result.stage = min(index + 1, dayIntervals.count)
        case .unknown:
            result.stage = 0
            result.lapses += 1
            result.dueAt = now.addingTimeInterval(5 * 60)
        case .fuzzy:
            result.stage = max(0, result.stage - 1)
            result.dueAt = now.addingTimeInterval(10 * 60)
        }
        return result
    }
}

public struct DailyQueue: Equatable, Sendable {
    public var due: [String]
    public var new: [String]
    public var studiedNewToday: Int
    public var nextReviewAt: Date?
    public var wordIDs: [String] { due + new }
}

public enum Learning {
    public static func selectedWordIDs(in state: AppState) -> [String] {
        var seen: Set<String> = []
        return state.decks.filter { state.activeDeckIDs.contains($0.id) }
            .flatMap(\.wordIDs).filter { seen.insert($0).inserted }
    }

    public static func queue(in state: AppState, at now: Date = Date(),
                             calendar: Calendar = .current) -> DailyQueue {
        let selected = selectedWordIDs(in: state)
        let learnedToday = Set(state.events.filter {
            $0.isFirstStudy && calendar.isDate($0.date, inSameDayAs: now)
        }.map(\.wordID)).count
        let due = selected.filter { state.progress[$0].map { $0.dueAt <= now } ?? false }
            .sorted {
                let lhs = state.progress[$0]!.dueAt, rhs = state.progress[$1]!.dueAt
                return lhs == rhs ? $0 < $1 : lhs < rhs
            }
        let budget = max(0, state.settings.dailyNewLimit - learnedToday)
        let fresh = Array(selected.filter { state.progress[$0] == nil }.prefix(budget))
        let next = selected.compactMap { state.progress[$0]?.dueAt }.filter { $0 > now }.min()
        return DailyQueue(due: due, new: fresh, studiedNewToday: learnedToday, nextReviewAt: next)
    }

    @discardableResult
    public static func rate(_ wordID: String, rating: Rating, in state: inout AppState,
                            at now: Date = Date(), calendar: Calendar = .current) throws -> ReviewReceipt {
        guard queue(in: state, at: now, calendar: calendar).wordIDs.contains(wordID) else {
            throw LearningError.notInQueue
        }
        let previous = state.progress[wordID]
        let event = ReviewEvent(id: UUID(), wordID: wordID, rating: rating,
                                date: now, isFirstStudy: previous == nil)
        let updated = Scheduler.review(previous, rating: rating, at: now, calendar: calendar)
        state.progress[wordID] = updated
        state.events.append(event)
        return ReviewReceipt(eventID: event.id, wordID: wordID, previous: previous, updated: updated)
    }

    public static func undo(_ receipt: ReviewReceipt, in state: inout AppState) throws {
        guard state.events.last?.id == receipt.eventID,
              state.progress[receipt.wordID] == receipt.updated else { throw LearningError.cannotUndo }
        state.events.removeLast()
        state.progress[receipt.wordID] = receipt.previous
    }

    public static func reviewedToday(in state: AppState, at now: Date = Date(),
                                      calendar: Calendar = .current) -> Int {
        Set(state.events.filter { calendar.isDate($0.date, inSameDayAs: now) }.map(\.wordID)).count
    }

    public static func streak(in state: AppState, at now: Date = Date(),
                              calendar: Calendar = .current) -> Int {
        let days = Set(state.events.map { calendar.startOfDay(for: $0.date) })
        var day = calendar.startOfDay(for: now)
        if !days.contains(day) { day = calendar.date(byAdding: .day, value: -1, to: day)! }
        var count = 0
        while days.contains(day) {
            count += 1
            day = calendar.date(byAdding: .day, value: -1, to: day)!
        }
        return count
    }
}

public struct ReviewReceipt: Sendable {
    public let eventID: UUID
    public let wordID: String
    public let previous: WordProgress?
    public let updated: WordProgress
}

public enum LearningError: Error, LocalizedError {
    case notInQueue, cannotUndo
    public var errorDescription: String? {
        switch self {
        case .notInQueue: "此词当前不在待学队列中，请刷新后继续。"
        case .cannotUndo: "只能撤销最近一次评分。"
        }
    }
}

public enum SwipeDirection: Equatable, Sendable {
    case left, right, down
    public var rating: Rating {
        switch self { case .left: .unknown; case .right: .known; case .down: .fuzzy }
    }
    public static func classify(x: Double, y: Double, threshold: Double = 80) -> Self? {
        if abs(x) >= threshold && abs(x) > abs(y) * 1.2 { return x > 0 ? .right : .left }
        if y >= threshold && y > abs(x) * 1.2 { return .down }
        return nil
    }
}
