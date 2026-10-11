import Foundation
import Observation

@MainActor
@Observable
final class LibraryStore {
    private(set) var entries: [LibraryEntry] = []
    private let repository: any LibraryRepository
    private let fileStore: any BookFileStore

    init(repository: any LibraryRepository, fileStore: any BookFileStore) {
        self.repository = repository
        self.fileStore = fileStore
    }

    func reload() throws {
        entries = try repository.entries()
    }

    func add(_ entry: LibraryEntry) throws {
        try repository.add(entry)
        try reload()
    }

    func delete(_ entry: LibraryEntry) throws {
        try repository.delete(entry)
        try reload()
        try fileStore.remove(for: entry)
    }
}
