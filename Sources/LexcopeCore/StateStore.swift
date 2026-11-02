import Foundation

/// The UI serializes access on the main actor. Disk is the source of truth:
/// callers publish a changed state only after save succeeds.
public struct StateStore {
    public let fileURL: URL
    public init(fileURL: URL) { self.fileURL = fileURL }

    public func load() throws -> AppState? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        let state = try JSONDecoder().decode(AppState.self, from: Data(contentsOf: fileURL))
        try state.validate()
        return state
    }

    public func save(_ state: AppState) throws {
        try state.validate()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(state)
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        try data.write(to: fileURL, options: [.atomic])
    }
}
