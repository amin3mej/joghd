import Foundation
import Observation

@MainActor
@Observable
final class LibraryStore {
    private(set) var entries: [LibraryEntry] = []
    var searchQuery = ""

    var filteredEntries: [LibraryEntry] {
        guard !searchQuery.isEmpty else {
            return entries
        }
        let options: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
        return entries.filter { entry in
            entry.title.range(of: searchQuery, options: options) != nil
                || entry.author?.range(of: searchQuery, options: options) != nil
        }
    }

    private let repository: any LibraryRepository
    private let fileStore: any BookFileStore

    init(repository: any LibraryRepository, fileStore: any BookFileStore) {
        self.repository = repository
        self.fileStore = fileStore
    }

    func reload() throws {
        entries = try repository.entries()
    }

    func upsert(_ entry: LibraryEntry) throws {
        try repository.upsert(entry)
        try reload()
    }

    func delete(_ entry: LibraryEntry) throws {
        try repository.delete(entry)
        try reload()
        try fileStore.remove(for: entry)
    }
}
