import Foundation

@MainActor
struct ImportService {
    private let fileStore: any BookFileStore

    init(fileStore: any BookFileStore) {
        self.fileStore = fileStore
    }

    func importFile(at source: URL) throws -> LibraryEntry {
        let entry = LibraryEntry(
            title: source.deletingPathExtension().lastPathComponent,
            format: try LibraryEntry.TextFormat(sourceURL: source)
        )
        let isAccessing = source.startAccessingSecurityScopedResource()
        defer { if isAccessing { source.stopAccessingSecurityScopedResource() } }

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
