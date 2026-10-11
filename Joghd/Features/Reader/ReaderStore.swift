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
    let entry: LibraryEntry
    private let fileStore: any BookFileStore

    init(entry: LibraryEntry, fileStore: any BookFileStore) {
        self.entry = entry
        self.fileStore = fileStore
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
}
