import Foundation

@MainActor
protocol BookFileStore {
    func store(_ source: URL, for entry: LibraryEntry) throws -> URL
    func remove(for entry: LibraryEntry) throws
}
