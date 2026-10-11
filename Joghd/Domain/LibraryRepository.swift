/// The shared boundary for the reader's on-device library.
/// Operations throw rather than treating unreadable or unwritable storage as empty.
@MainActor
protocol LibraryRepository {
    func entries() throws -> [LibraryEntry]
    func add(_ entry: LibraryEntry) throws
}
