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

    func upsert(_ entry: LibraryEntry) throws {
        if shouldFail { throw Failure.unavailable }
        if let index = savedEntries.firstIndex(where: { $0.id == entry.id }) {
            savedEntries[index] = entry
        } else {
            savedEntries.append(entry)
        }
    }

    func delete(_ entry: LibraryEntry) throws {
        if shouldFail { throw Failure.unavailable }
        savedEntries.removeAll { $0.id == entry.id }
    }
}
