import Foundation

@testable import Joghd

@MainActor
final class TestBookFileStore: BookFileStore {
    private enum Failure: Error {
        case unavailable
    }

    var storedSources: [UUID: URL] = [:]
    private(set) var removedEntries: [UUID] = []
    var storedData: [UUID: Data] = [:]
    var shouldFail = false

    func store(_ source: URL, for entry: LibraryEntry) async throws -> URL {
        await Task.yield()
        if shouldFail { throw Failure.unavailable }
        storedSources[entry.id] = source
        storedData[entry.id] = try Data(contentsOf: source)
        return source
    }

    func remove(for entry: LibraryEntry) throws {
        if shouldFail { throw Failure.unavailable }
        removedEntries.append(entry.id)
    }
}
