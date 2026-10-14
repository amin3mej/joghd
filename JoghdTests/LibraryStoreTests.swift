import Foundation
import Testing

@testable import Joghd

@MainActor
struct LibraryStoreTests {
    @Test
    func searchWithNoMatchesKeepsLibraryEntriesAndCanBeCleared() throws {
        let anonymous = LibraryEntry(title: "Anonymous", format: .epub)
        let store = LibraryStore(
            repository: TestLibraryRepository(savedEntries: [anonymous]),
            fileStore: TestBookFileStore()
        )
        try store.reload()

        store.searchQuery = "missing"
        #expect(store.filteredEntries.isEmpty)
        #expect(store.entries == [anonymous])
        store.searchQuery = "ANON"
        #expect(store.filteredEntries == [anonymous])
        store.searchQuery = ""
        #expect(store.filteredEntries == [anonymous])
    }

    @Test
    func reloadAndUpsertRespectActiveSearchWithoutResettingQuery() throws {
        let dune = LibraryEntry(title: "Dune", format: .epub)
        let repository = TestLibraryRepository(savedEntries: [dune])
        let store = LibraryStore(repository: repository, fileStore: TestBookFileStore())
        try store.reload()
        store.searchQuery = "DUNE"

        let sequel = LibraryEntry(title: "Dune Messiah", format: .epub)
        try repository.upsert(sequel)
        try store.reload()
        #expect(store.searchQuery == "DUNE")
        #expect(store.filteredEntries == [dune, sequel])

        let unrelated = LibraryEntry(title: "Foundation", format: .epub)
        try store.upsert(unrelated)
        #expect(store.filteredEntries == [dune, sequel])
        var revised = unrelated
        revised.author = "Dune historian"
        try store.upsert(revised)
        #expect(store.filteredEntries == [dune, sequel, revised])
        #expect(store.searchQuery == "DUNE")
    }

    @Test
    func failedReloadAndDeletionRetainActiveSearch() throws {
        let dune = LibraryEntry(title: "Dune", format: .epub)
        let repository = TestLibraryRepository(savedEntries: [dune])
        let store = LibraryStore(repository: repository, fileStore: TestBookFileStore())
        try store.reload()
        store.searchQuery = "dune"
        repository.shouldFail = true

        #expect(throws: (any Error).self) { try store.reload() }
        #expect(store.filteredEntries == [dune])
        #expect(store.searchQuery == "dune")
        repository.shouldFail = false
        try store.delete(dune)
        #expect(store.entries.isEmpty)
        #expect(store.filteredEntries.isEmpty)
        #expect(store.searchQuery == "dune")
    }

    @Test(arguments: ["CAFE", "fé", "garcia", "MÁRQUEZ"])
    func searchIgnoresCaseAndAccentsInTitleAndOptionalAuthor(query: String) throws {
        let cafe = LibraryEntry(title: "Café", author: "Gabriel García Márquez", format: .epub)
        let anonymous = LibraryEntry(title: "Anonymous", format: .epub)
        let store = LibraryStore(
            repository: TestLibraryRepository(savedEntries: [anonymous, cafe]),
            fileStore: TestBookFileStore()
        )
        try store.reload()

        store.searchQuery = query
        #expect(store.filteredEntries == [cafe])
    }

    @Test
    func searchMatchesTitleSubstringsAndClearingRestoresOrder() throws {
        let dune = LibraryEntry(title: "Dune", format: .epub)
        let foundation = LibraryEntry(title: "Foundation", format: .epub)
        let sequel = LibraryEntry(title: "Dune Messiah", format: .epub)
        let store = LibraryStore(
            repository: TestLibraryRepository(savedEntries: [dune, foundation, sequel]),
            fileStore: TestBookFileStore()
        )
        try store.reload()

        #expect(store.filteredEntries == [dune, foundation, sequel])
        store.searchQuery = "une"
        #expect(store.filteredEntries == [dune, sequel])
        #expect(store.entries == [dune, foundation, sequel])
        store.searchQuery = ""
        #expect(store.filteredEntries == [dune, foundation, sequel])
    }

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
    func upsertAppendsEntry() throws {
        let store = LibraryStore(
            repository: TestLibraryRepository(),
            fileStore: TestBookFileStore()
        )
        try store.upsert(LibraryEntry(title: "Dune", author: "Frank Herbert", format: .epub))

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
        let store = LibraryStore(
            repository: FileLibraryRepository(documentURL: url),
            fileStore: TestBookFileStore()
        )
        let entry = LibraryEntry(title: "Dune", author: "Frank Herbert", format: .epub)
        try store.upsert(entry)

        let relaunched = LibraryStore(
            repository: FileLibraryRepository(documentURL: url),
            fileStore: TestBookFileStore()
        )
        try relaunched.reload()
        #expect(relaunched.entries == [entry])
    }

    @Test
    func failedUpsertLeavesDisplayedAndSavedEntriesUnchanged() throws {
        let entry = LibraryEntry(title: "Dune", format: .epub)
        let repository = TestLibraryRepository(savedEntries: [entry])
        let store = LibraryStore(repository: repository, fileStore: TestBookFileStore())
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
        let store = LibraryStore(repository: repository, fileStore: TestBookFileStore())
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
    func deletionSurvivesNewStore() async throws {
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
        try store.upsert(entry)
        let source = directory.appendingPathComponent("Dune.epub")
        try Data("book".utf8).write(to: source)
        let storedFile = try await fileStore.store(source, for: entry)

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

    @Test
    func backfillPopulatesMissingCoverFromStoredEpub() async throws {
        let source = try coverEpub()
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }
        let entry = LibraryEntry(title: "The Book", format: .epub)
        let repository = TestLibraryRepository(savedEntries: [entry])
        let fileStore = TestBookFileStore()
        fileStore.storedSources[entry.id] = source
        let store = LibraryStore(repository: repository, fileStore: fileStore)
        try store.reload()

        await store.backfillMissingCovers()

        let backed = try #require(store.entries.first?.coverImageData)
        #expect(CoverFixture.pixelSize(of: backed) != nil)
        #expect(repository.savedEntries.first?.coverImageData != nil)
    }

    @Test
    func backfillPopulatesCoverDeclaredByTheEpub2Meta() async throws {
        let source = try TestFiles.source(
            named: "MetaCover.epub",
            contents: EpubCoverFixture.epub(
                manifest: [(id: "a", href: "a.xhtml"), (id: "cover-image", href: "cover.jpg")],
                metaCoverID: "cover-image",
                resources: [("OEBPS/cover.jpg", CoverFixture.imageData(width: 400, height: 600))]
            )
        )
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }
        let entry = LibraryEntry(title: "Protocols", format: .epub)
        let repository = TestLibraryRepository(savedEntries: [entry])
        let fileStore = TestBookFileStore()
        fileStore.storedSources[entry.id] = source
        let store = LibraryStore(repository: repository, fileStore: fileStore)
        try store.reload()

        await store.backfillMissingCovers()

        let backed = try #require(store.entries.first?.coverImageData)
        #expect(CoverFixture.pixelSize(of: backed) != nil)
        #expect(repository.savedEntries.first?.coverImageData != nil)
    }

    @Test
    func backfillLeavesCoverlessEpubUnchanged() async throws {
        let source = try TestFiles.source(
            named: "NoCover.epub",
            contents: EpubCoverFixture.epub()
        )
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }
        let entry = LibraryEntry(title: "The Book", format: .epub)
        let repository = TestLibraryRepository(savedEntries: [entry])
        let fileStore = TestBookFileStore()
        fileStore.storedSources[entry.id] = source
        let store = LibraryStore(repository: repository, fileStore: fileStore)
        try store.reload()

        await store.backfillMissingCovers()

        #expect(store.entries.first?.coverImageData == nil)
        #expect(repository.savedEntries.first?.coverImageData == nil)
    }

    @Test
    func backfillSkipsMarkdownEntries() async throws {
        let entry = LibraryEntry(title: "Notes", format: .markdown)
        let repository = TestLibraryRepository(savedEntries: [entry])
        let store = LibraryStore(repository: repository, fileStore: TestBookFileStore())
        try store.reload()

        await store.backfillMissingCovers()

        #expect(store.entries.first?.coverImageData == nil)
    }

    @Test
    func backfillPreservesExistingCover() async throws {
        let cover = Data("thumbnail".utf8)
        let entry = LibraryEntry(title: "Dune", format: .epub, coverImageData: cover)
        let repository = TestLibraryRepository(savedEntries: [entry])
        let store = LibraryStore(repository: repository, fileStore: TestBookFileStore())
        try store.reload()

        await store.backfillMissingCovers()

        #expect(store.entries.first?.coverImageData == cover)
        #expect(repository.savedEntries.first?.coverImageData == cover)
    }

    @Test
    func backfillSkipsEntryWithMissingStoredFile() async throws {
        let entry = LibraryEntry(title: "Gone", format: .epub)
        let repository = TestLibraryRepository(savedEntries: [entry])
        let store = LibraryStore(repository: repository, fileStore: TestBookFileStore())
        try store.reload()

        await store.backfillMissingCovers()

        #expect(store.entries.first?.coverImageData == nil)
        #expect(repository.savedEntries.first?.coverImageData == nil)
    }

    private func coverEpub() throws -> URL {
        try TestFiles.source(
            named: "Cover.epub",
            contents: EpubCoverFixture.epub(
                manifest: [(id: "a", href: "a.xhtml"), (id: "cover", href: "cover.png")],
                properties: ["cover": "cover-image"],
                resources: [("OEBPS/cover.png", CoverFixture.imageData(width: 400, height: 600))]
            )
        )
    }
}
