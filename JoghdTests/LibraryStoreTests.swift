import Foundation
import Testing

@testable import Joghd

@MainActor
struct LibraryStoreTests {
    @Test
    func startsEmpty() throws {
        let store = LibraryStore(repository: TestLibraryRepository())
        try store.reload()
        #expect(store.entries.isEmpty)
    }

    @Test
    func upsertAppendsEntry() throws {
        let store = LibraryStore(repository: TestLibraryRepository())
        try store.upsert(LibraryEntry(title: "Dune", author: "Frank Herbert", format: .epub))

        #expect(store.entries.count == 1)
        #expect(store.entries.first?.title == "Dune")
    }

    @Test
    func reloadListsEntriesFromRepository() throws {
        let entry = LibraryEntry(title: "Dune", format: .epub)
        let repository = TestLibraryRepository(savedEntries: [entry])
        let store = LibraryStore(repository: repository)
        try store.reload()
        #expect(store.entries == [entry])

        let second = LibraryEntry(title: "Foundation", format: .pdf)
        try repository.upsert(second)
        try store.reload()
        #expect(store.entries == [entry, second])
    }

    @Test
    func entryAddedThroughStoreSurvivesNewStore() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("library.json")
        let store = LibraryStore(repository: FileLibraryRepository(documentURL: url))
        let entry = LibraryEntry(title: "Dune", author: "Frank Herbert", format: .epub)
        try store.upsert(entry)

        let relaunched = LibraryStore(repository: FileLibraryRepository(documentURL: url))
        try relaunched.reload()
        #expect(relaunched.entries == [entry])
    }

    @Test
    func failedUpsertLeavesDisplayedAndSavedEntriesUnchanged() throws {
        let entry = LibraryEntry(title: "Dune", format: .epub)
        let repository = TestLibraryRepository(savedEntries: [entry])
        let store = LibraryStore(repository: repository)
        try store.reload()
        repository.shouldFail = true
        #expect(throws: (any Error).self) {
            try store.upsert(LibraryEntry(title: "Foundation", format: .pdf))
        }
        #expect(store.entries == [entry])
        repository.shouldFail = false
        #expect(try repository.entries() == [entry])
    }

    @Test
    func upsertReplacesPersistedEntryWithSameID() throws {
        let entry = LibraryEntry(title: "Dune", format: .epub)
        let repository = TestLibraryRepository(savedEntries: [entry])
        let store = LibraryStore(repository: repository)
        try store.reload()

        var revised = entry
        revised.title = "Dune (Revised)"
        revised.author = "Frank Herbert"
        try store.upsert(revised)

        #expect(store.entries == [revised])
        #expect(try repository.entries() == [revised])
    }

    @Test
    func failedReloadReportsErrorAndPreservesDisplayedEntries() throws {
        let entry = LibraryEntry(title: "Dune", format: .epub)
        let repository = TestLibraryRepository(savedEntries: [entry])
        let store = LibraryStore(repository: repository)
        try store.reload()
        repository.shouldFail = true
        #expect(throws: (any Error).self) { try store.reload() }
        #expect(store.entries == [entry])
    }
}
