import Foundation

@MainActor
final class PreviewLibraryRepository: LibraryRepository {
    private var storedEntries: [LibraryEntry] = []

    func entries() -> [LibraryEntry] {
        storedEntries
    }

    func upsert(_ entry: LibraryEntry) {
        if let index = storedEntries.firstIndex(where: { $0.id == entry.id }) {
            storedEntries[index] = entry
        } else {
            storedEntries.append(entry)
        }
    }
}
