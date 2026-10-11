import Foundation

/// A single library document, replaced atomically on each successful addition.
@MainActor
final class FileLibraryRepository: LibraryRepository {
    private let documentURL: URL

    init(documentURL: URL = URL.applicationSupportDirectory
        .appendingPathComponent("Joghd", isDirectory: true)
        .appendingPathComponent("library.json")) {
        self.documentURL = documentURL
    }

    func entries() throws -> [LibraryEntry] {
        let data: Data
        do {
            data = try Data(contentsOf: documentURL)
        } catch let error as NSError where error.domain == NSCocoaErrorDomain
            && error.code == NSFileReadNoSuchFileError {
            return []
        }
        return try JSONDecoder().decode([LibraryEntry].self, from: data)
    }

    func add(_ entry: LibraryEntry) throws {
        var updated = try entries()
        updated.append(entry)
        let data = try JSONEncoder().encode(updated)
        try FileManager.default.createDirectory(
            at: documentURL.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        try data.write(to: documentURL, options: .atomic)
    }
}
