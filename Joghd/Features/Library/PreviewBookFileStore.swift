import Foundation

@MainActor
final class PreviewBookFileStore: BookFileStore {
    private var storedSources: [UUID: URL] = [:]

    func store(_ source: URL, for entry: LibraryEntry) -> URL {
        storedSources[entry.id] = source
        return source
    }

    func storedFile(for entry: LibraryEntry) throws -> URL {
        guard let source = storedSources[entry.id] else {
            throw BookFileError.missingFile
        }
        return source
    }

    func remove(for entry: LibraryEntry) {
        storedSources.removeValue(forKey: entry.id)
    }
}
