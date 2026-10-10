import Testing

@testable import Joghd

struct LibraryStoreTests {
    @Test
    func startsEmpty() {
        let store = LibraryStore()
        #expect(store.entries.isEmpty)
    }

    @Test
    func addAppendsEntry() {
        let store = LibraryStore()
        store.add(LibraryEntry(title: "Dune", author: "Frank Herbert", format: .epub))

        #expect(store.entries.count == 1)
        #expect(store.entries.first?.title == "Dune")
    }
}
