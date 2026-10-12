import Foundation
import Observation

@MainActor
@Observable
final class ReaderStore {
    enum State: Equatable {
        case loading
        case loaded(BookDocument)
        case failed(String)
    }

    private(set) var state: State = .loading
    private(set) var entry: LibraryEntry
    private(set) var position: Location?
    private(set) var saveError: String?
    private let fileStore: any BookFileStore
    private let repository: any LibraryRepository

    init(entry: LibraryEntry, fileStore: any BookFileStore, repository: any LibraryRepository) {
        self.entry = entry
        self.fileStore = fileStore
        self.repository = repository
        self.position = entry.readingPosition
    }

    nonisolated private static func document(
        at url: URL, format: LibraryEntry.TextFormat
    ) throws -> BookDocument {
        switch format {
        case .epub:
            try EpubBookParser().parse(contentsOf: url)

        case .markdown:
            try MarkdownBookParser().parse(contentsOf: url)

        case .pdf:
            throw ReaderError.unsupportedFormat
        }
    }

    private static func message(for error: any Error) -> String {
        (error as? any LocalizedError)?.errorDescription ?? error.localizedDescription
    }

    func load() async {
        state = .loading
        refreshEntry()
        do {
            let fileURL = try fileStore.storedFile(for: entry)
            let format = entry.format
            let document = try await Task.detached(priority: .userInitiated) {
                try Self.document(at: fileURL, format: format)
            }.value
            state = .loaded(document)
        } catch {
            state = .failed(Self.message(for: error))
        }
    }

    func record(_ location: Location) {
        guard location != position else {
            return
        }
        position = location
        entry.readingPosition = location
        do {
            try repository.upsert(entry)
            saveError = nil
        } catch {
            saveError = Self.message(for: error)
        }
    }

    func clearSaveError() {
        saveError = nil
    }

    private func refreshEntry() {
        guard let stored = try? repository.entries().first(where: { $0.id == entry.id }) else {
            return
        }
        entry = stored
        position = stored.readingPosition
    }
}
