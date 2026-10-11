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

    nonisolated private static func stage(source: URL) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let staged = directory.appendingPathComponent(source.lastPathComponent)
        do {
            try FileManager.default.copyItem(at: source.resolvingSymlinksInPath(), to: staged)
        } catch {
            try? FileManager.default.removeItem(at: directory)
            throw error
        }
        return staged
    }

    nonisolated private static func metadata(
        at source: URL, format: LibraryEntry.TextFormat
    ) throws -> BookMetadata {
        switch format {
        case .epub:
            try EpubBookParser().metadata(contentsOf: source)

        case .markdown:
            try MarkdownBookParser().metadata(contentsOf: source)

        case .pdf:
            throw ImportError.unsupportedFormat
        }
    }

    func draft(for source: URL) throws -> ImportDraft {
        let format = try LibraryEntry.TextFormat(sourceURL: source)
        let isAccessing = source.startAccessingSecurityScopedResource()
        defer { if isAccessing { source.stopAccessingSecurityScopedResource() } }
        let metadata = try? Self.metadata(at: source, format: format)
        return ImportDraft(
            source: source,
            format: format,
            title: metadata?.title ?? source.deletingPathExtension().lastPathComponent,
            author: metadata?.author ?? ""
        )
    }

    func confirm(_ draft: ImportDraft) async throws -> LibraryEntry {
        let entry = LibraryEntry(
            title: draft.title,
            author: author(from: draft),
            format: draft.format
        )
        let isAccessing = draft.source.startAccessingSecurityScopedResource()
        defer { if isAccessing { draft.source.stopAccessingSecurityScopedResource() } }

        let staged: URL
        do {
            staged = try await Task.detached(priority: .userInitiated) {
                try Self.stage(source: draft.source)
            }.value
        } catch {
            throw ImportError.unreadableFile
        }
        defer { try? FileManager.default.removeItem(at: staged.deletingLastPathComponent()) }

        do {
            _ = try await Task.detached(priority: .userInitiated) {
                try Self.openDocument(at: staged, format: draft.format)
            }.value
        } catch {
            throw ImportError.unreadableFile
        }

        _ = try await fileStore.store(staged, for: entry)
        return entry
    }

    func revise(_ entry: LibraryEntry, with draft: ImportDraft) -> LibraryEntry {
        var revised = entry
        revised.title = draft.title
        revised.author = author(from: draft)
        return revised
    }

    private func author(from draft: ImportDraft) -> String? {
        draft.author.isEmpty ? nil : draft.author
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
