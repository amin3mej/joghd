import Foundation

@MainActor
struct ImportService {
    private let fileStore: any BookFileStore

    init(fileStore: any BookFileStore) {
        self.fileStore = fileStore
    }

    nonisolated private static func openDocument(
        at source: URL, format: LibraryEntry.TextFormat
    ) throws -> BookDocument {
        switch format {
        case .epub:
            try EpubBookParser().parse(contentsOf: source)

        case .markdown:
            try MarkdownBookParser().parse(contentsOf: source)

        case .pdf:
            throw ImportError.unsupportedFormat
        }
    }

    func importFile(at source: URL) async throws -> LibraryEntry {
        let format = try LibraryEntry.TextFormat(sourceURL: source)
        let entry = LibraryEntry(
            title: source.deletingPathExtension().lastPathComponent,
            format: format
        )
        let isAccessing = source.startAccessingSecurityScopedResource()
        defer { if isAccessing { source.stopAccessingSecurityScopedResource() } }

        do {
            _ = try await Task.detached(priority: .userInitiated) {
                try Self.openDocument(at: source, format: format)
            }.value
        } catch {
            throw ImportError.unreadableFile
        }

        _ = try fileStore.store(source, for: entry)
        return entry
    }
}

extension LibraryEntry.TextFormat {
    init(sourceURL: URL) throws {
        switch sourceURL.pathExtension.lowercased() {
        case "epub":
            self = .epub

        case "md", "markdown":
            self = .markdown

        default:
            throw ImportError.unsupportedFormat
        }
    }
}
