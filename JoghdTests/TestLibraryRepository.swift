@testable import Joghd

@MainActor
final class TestLibraryRepository: LibraryRepository {
    private enum Failure: Error {
        case unavailable
    }

    var savedEntries: [LibraryEntry]
    var shouldFail = false

    init(savedEntries: [LibraryEntry] = []) {
        self.savedEntries = savedEntries
    }

    func entries() throws -> [LibraryEntry] {
        if shouldFail { throw Failure.unavailable }
        return savedEntries
    }

    func add(_ entry: LibraryEntry) throws {
        if shouldFail { throw Failure.unavailable }
        savedEntries.append(entry)
    }
}
