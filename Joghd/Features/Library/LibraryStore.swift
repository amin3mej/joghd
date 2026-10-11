import Foundation
import Observation

/// Observable projection of the library repository for the Library screen.
@MainActor
@Observable
final class LibraryStore {
    private(set) var entries: [LibraryEntry] = []
    private let repository: any LibraryRepository

    init(repository: any LibraryRepository) {
        self.repository = repository
    }

    func reload() throws {
        entries = try repository.entries()
    }

    func add(_ entry: LibraryEntry) throws {
        try repository.add(entry)
        try reload()
    }
}
