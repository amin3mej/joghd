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
    func addAppendsEntry() throws {
        let store = LibraryStore(repository: TestLibraryRepository())
        try store.add(LibraryEntry(title: "Dune", author: "Frank Herbert", format: .epub))

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
        try repository.add(second)
        try store.reload()
        #expect(store.entries == [entry, second])
    }

    @Test
    func entryAddedThroughStoreSurvivesNewStore() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("library.json")
        let store = LibraryStore(repository: FileLibraryRepository(documentURL: url))
        let entry = LibraryEntry(title: "Dune", author: "Frank Herbert", format: .epub)
        try store.add(entry)

        let relaunched = LibraryStore(repository: FileLibraryRepository(documentURL: url))
        try relaunched.reload()
        #expect(relaunched.entries == [entry])
    }

    @Test
    func failedAdditionLeavesDisplayedAndSavedEntriesUnchanged() throws {
        let entry = LibraryEntry(title: "Dune", format: .epub)
        let repository = TestLibraryRepository(savedEntries: [entry])
        let store = LibraryStore(repository: repository)
        try store.reload()
        repository.shouldFail = true
        #expect(throws: (any Error).self) {
            try store.add(LibraryEntry(title: "Foundation", format: .pdf))
        }
        #expect(store.entries == [entry])
        repository.shouldFail = false
        #expect(try repository.entries() == [entry])
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

@MainActor
private final class TestLibraryRepository: LibraryRepository {
    var savedEntries: [LibraryEntry]
    var shouldFail = false
    private enum Failure: Error { case unavailable }

    init(savedEntries: [LibraryEntry] = []) {
        self.savedEntries = savedEntries
    }

    func entries() throws -> [LibraryEntry] {
        if shouldFail { throw Failure.unavailable }
        return savedEntries
    }

    func add(_ entry: LibraryEntry) throws {
        if shouldFail { throw Failure.unavailable }
        savedEntries.append(entry)
    }
}
