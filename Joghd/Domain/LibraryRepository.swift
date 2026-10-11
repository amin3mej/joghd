@MainActor
protocol LibraryRepository {
    func entries() throws -> [LibraryEntry]
    func add(_ entry: LibraryEntry) throws
    func delete(_ entry: LibraryEntry) throws
}
