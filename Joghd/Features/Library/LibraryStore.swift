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

    nonisolated private static func coverThumbnail(fromEpubAt url: URL) -> Data? {
        guard let cover = try? EpubBookParser().coverImage(contentsOf: url) else {
            return nil
        }
        return BookCoverThumbnail.make(from: cover)
    }

    func reload() throws {
        entries = try repository.entries()
    }

    func backfillMissingCovers() async {
        guard let current = try? repository.entries() else {
            return
        }
        var didUpdate = false
        for var entry in current where entry.coverImageData == nil {
            guard entry.format == .epub else {
                continue
            }
            guard let fileURL = try? fileStore.storedFile(for: entry) else {
                continue
            }
            let thumbnail = await Task.detached(priority: .utility) {
                Self.coverThumbnail(fromEpubAt: fileURL)
            }.value
            guard let thumbnail else {
                continue
            }
            entry.coverImageData = thumbnail
            do {
                try repository.upsert(entry)
                didUpdate = true
            } catch {
                continue
            }
        }
        if didUpdate {
            try? reload()
        }
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
