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

    func store(_ source: URL, for entry: LibraryEntry) throws -> URL {
        let entryDirectory =
            directoryURL
            .appendingPathComponent(entry.id.uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: entryDirectory, withIntermediateDirectories: true
        )
        let destination = entryDirectory.appendingPathComponent(source.lastPathComponent)
        try FileManager.default.copyItem(at: source, to: destination)
        return destination
    }
}
