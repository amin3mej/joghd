import Foundation

@MainActor
protocol BookFileStore {
    func store(_ source: URL, for entry: LibraryEntry) async throws -> URL
}
