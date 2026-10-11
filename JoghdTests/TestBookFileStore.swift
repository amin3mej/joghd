import Foundation

@testable import Joghd

@MainActor
final class TestBookFileStore: BookFileStore {
    private enum Failure: Error {
        case unavailable
    }

    var storedSources: [UUID: URL] = [:]
    private(set) var removedEntries: [UUID] = []
    var shouldFail = false

    func store(_ source: URL, for entry: LibraryEntry) throws -> URL {
        if shouldFail { throw Failure.unavailable }
        storedSources[entry.id] = source
        return source
    }

    func remove(for entry: LibraryEntry) throws {
        if shouldFail { throw Failure.unavailable }
        removedEntries.append(entry.id)
    }
}
