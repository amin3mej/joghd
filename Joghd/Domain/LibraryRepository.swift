@MainActor
protocol LibraryRepository {
    func entries() throws -> [LibraryEntry]
    func upsert(_ entry: LibraryEntry) throws
}
