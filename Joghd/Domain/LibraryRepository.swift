@MainActor
protocol LibraryRepository {
    func entries() throws -> [LibraryEntry]
    func upsert(_ entry: LibraryEntry) throws
    func delete(_ entry: LibraryEntry) throws
}
