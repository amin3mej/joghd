import Foundation

@MainActor
final class PreviewLibraryRepository: LibraryRepository {
    private var storedEntries: [LibraryEntry] = []

    func entries() -> [LibraryEntry] {
        storedEntries
    }

    func add(_ entry: LibraryEntry) {
        storedEntries.append(entry)
    }
}
