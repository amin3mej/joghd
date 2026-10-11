import Foundation

@MainActor
final class FileBookFileStore: BookFileStore {
    private let directoryURL: URL

    init(
        directoryURL: URL = URL.applicationSupportDirectory
            .appendingPathComponent("Joghd", isDirectory: true)
            .appendingPathComponent("Books", isDirectory: true)
    ) {
        self.directoryURL = directoryURL
    }

    func store(_ source: URL, for entry: LibraryEntry) async throws -> URL {
        let directory = directoryURL
        return try await Task.detached(priority: .userInitiated) {
            let entryDirectory =
                directory
                .appendingPathComponent(entry.id.uuidString, isDirectory: true)
            try FileManager.default.createDirectory(
                at: entryDirectory, withIntermediateDirectories: true
            )
            let destination = entryDirectory.appendingPathComponent(source.lastPathComponent)
            try FileManager.default.copyItem(at: source, to: destination)
            return destination
        }.value
    }

    func remove(for entry: LibraryEntry) throws {
        let entryDirectory = entryDirectory(for: entry)
        guard FileManager.default.fileExists(atPath: entryDirectory.path) else {
            return
        }
        try FileManager.default.removeItem(at: entryDirectory)
    }

    private func entryDirectory(for entry: LibraryEntry) -> URL {
        directoryURL
            .appendingPathComponent(entry.id.uuidString, isDirectory: true)
    }
}
