import Foundation
import Testing

@testable import Joghd

@MainActor
struct LibraryStoreTests {
    @Test
    func startsEmpty() throws {
        let store = LibraryStore(
            repository: TestLibraryRepository(),
            fileStore: TestBookFileStore()
        )
        try store.reload()
        #expect(store.entries.isEmpty)
    }

    @Test
    func addAppendsEntry() throws {
        let store = LibraryStore(
            repository: TestLibraryRepository(),
            fileStore: TestBookFileStore()
        )
        try store.add(LibraryEntry(title: "Dune", author: "Frank Herbert", format: .epub))

        #expect(store.entries.count == 1)
        #expect(store.entries.first?.title == "Dune")
    }

    @Test
    func reloadListsEntriesFromRepository() throws {
        let entry = LibraryEntry(title: "Dune", format: .epub)
        let repository = TestLibraryRepository(savedEntries: [entry])
        let store = LibraryStore(repository: repository, fileStore: TestBookFileStore())
        try store.reload()
        #expect(store.entries == [entry])

        let second = LibraryEntry(title: "Foundation", format: .pdf)
        try repository.add(second)
        try store.reload()
        #expect(store.entries == [entry, second])
    }

    @Test
    func entryAddedThroughStoreSurvivesNewStore() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("library.json")
        let store = LibraryStore(
            repository: FileLibraryRepository(documentURL: url),
            fileStore: TestBookFileStore()
        )
        let entry = LibraryEntry(title: "Dune", author: "Frank Herbert", format: .epub)
        try store.add(entry)

        let relaunched = LibraryStore(
            repository: FileLibraryRepository(documentURL: url),
            fileStore: TestBookFileStore()
        )
        try relaunched.reload()
        #expect(relaunched.entries == [entry])
    }

    @Test
    func failedAdditionLeavesDisplayedAndSavedEntriesUnchanged() throws {
        let entry = LibraryEntry(title: "Dune", format: .epub)
        let repository = TestLibraryRepository(savedEntries: [entry])
        let store = LibraryStore(repository: repository, fileStore: TestBookFileStore())
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
        let store = LibraryStore(repository: repository, fileStore: TestBookFileStore())
        try store.reload()
        repository.shouldFail = true
        #expect(throws: (any Error).self) { try store.reload() }
        #expect(store.entries == [entry])
    }

    @Test
    func deleteRemovesEntryFromDisplayedEntriesAndRepository() throws {
        let entry = LibraryEntry(title: "Dune", format: .epub)
        let repository = TestLibraryRepository(savedEntries: [entry])
        let fileStore = TestBookFileStore()
        let store = LibraryStore(repository: repository, fileStore: fileStore)
        try store.reload()

        try store.delete(entry)

        #expect(store.entries.isEmpty)
        #expect(try repository.entries().isEmpty)
        #expect(fileStore.removedEntries == [entry.id])
    }

    @Test
    func deletionSurvivesNewStore() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let documentURL = directory.appendingPathComponent("library.json")
        let booksDirectory = directory.appendingPathComponent("Books", isDirectory: true)
        let fileStore = FileBookFileStore(directoryURL: booksDirectory)
        let entry = LibraryEntry(title: "Dune", format: .epub)
        let store = LibraryStore(
            repository: FileLibraryRepository(documentURL: documentURL),
            fileStore: fileStore
        )
        try store.add(entry)
        let source = directory.appendingPathComponent("Dune.epub")
        try Data("book".utf8).write(to: source)
        let storedFile = try fileStore.store(source, for: entry)

        try store.delete(entry)

        let relaunched = LibraryStore(
            repository: FileLibraryRepository(documentURL: documentURL),
            fileStore: fileStore
        )
        try relaunched.reload()
        #expect(relaunched.entries.isEmpty)
        #expect(!FileManager.default.fileExists(atPath: storedFile.path))
    }

    @Test
    func failedEntryDeletionLeavesEntryAndFileIntact() throws {
        let entry = LibraryEntry(title: "Dune", format: .epub)
        let repository = TestLibraryRepository(savedEntries: [entry])
        let fileStore = TestBookFileStore()
        let store = LibraryStore(repository: repository, fileStore: fileStore)
        try store.reload()
        repository.shouldFail = true

        #expect(throws: (any Error).self) {
            try store.delete(entry)
        }

        #expect(store.entries == [entry])
        repository.shouldFail = false
        #expect(try repository.entries() == [entry])
        #expect(fileStore.removedEntries.isEmpty)
    }

    @Test
    func failedFileRemovalStillRemovesEntry() throws {
        let entry = LibraryEntry(title: "Dune", format: .epub)
        let repository = TestLibraryRepository(savedEntries: [entry])
        let fileStore = TestBookFileStore()
        fileStore.shouldFail = true
        let store = LibraryStore(repository: repository, fileStore: fileStore)
        try store.reload()

        #expect(throws: (any Error).self) {
            try store.delete(entry)
        }

        #expect(store.entries.isEmpty)
        #expect(try repository.entries().isEmpty)
    }
}
