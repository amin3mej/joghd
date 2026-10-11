import Foundation

@MainActor
struct ImportService {
    private let fileStore: any BookFileStore

    init(fileStore: any BookFileStore) {
        self.fileStore = fileStore
    }

    func draft(for source: URL) throws -> ImportDraft {
        ImportDraft(
            source: source,
            format: try LibraryEntry.TextFormat(sourceURL: source),
            title: source.deletingPathExtension().lastPathComponent
        )
    }

    func confirm(_ draft: ImportDraft) throws -> LibraryEntry {
        let entry = LibraryEntry(
            title: draft.title,
            author: draft.author.isEmpty ? nil : draft.author,
            format: draft.format
        )
        let isAccessing = draft.source.startAccessingSecurityScopedResource()
        defer { if isAccessing { draft.source.stopAccessingSecurityScopedResource() } }

        _ = try fileStore.store(draft.source, for: entry)
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
