import Foundation
import Testing

@testable import Joghd

@MainActor
struct ImportServiceTests {
    private func makeSourceFile(named name: String, contents: Data = Data()) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(name)
        try contents.write(to: url)
        return url
    }

    private func makeEpub(
        named name: String = "Dune.epub",
        title: String? = "The Book",
        author: String? = "The Author"
    ) throws -> URL {
        let data = EpubFixture.zip {
            ("META-INF/container.xml", EpubFixture.container)
            (
                "OEBPS/content.opf",
                EpubFixture.package(
                    title: title,
                    author: author,
                    manifest: [(id: "a", href: "a.xhtml")],
                    spine: ["a"]
                )
            )
            ("OEBPS/a.xhtml", EpubFixture.chapter(title: "A", body: "<p>Body</p>"))
        }
        return try makeSourceFile(named: name, contents: data)
    }

    @Test
    func draftPrefillsTitleAndAuthorFromEpubPackage() throws {
        let source = try makeEpub()
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }

        let draft = try ImportService(fileStore: TestBookFileStore()).draft(for: source)

        #expect(draft.title == "The Book")
        #expect(draft.author == "The Author")
        #expect(draft.format == .epub)
        #expect(draft.source == source)
    }

    @Test
    func draftPrefillsTitleAndAuthorFromMarkdownFrontMatter() throws {
        let source = try makeSourceFile(
            named: "Notes.md",
            contents: Data("---\ntitle: My Notes\nauthor: Jane Doe\n---\n\n# Chapter\n\nBody.".utf8)
        )
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }

        let draft = try ImportService(fileStore: TestBookFileStore()).draft(for: source)

        #expect(draft.title == "My Notes")
        #expect(draft.author == "Jane Doe")
        #expect(draft.format == .markdown)
    }

    @Test
    func draftFallsBackToFilenameWhenFileCarriesNeither() throws {
        let source = try makeEpub(named: "Dune.epub", title: nil, author: nil)
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }

        let draft = try ImportService(fileStore: TestBookFileStore()).draft(for: source)

        #expect(draft.title == "Dune")
        #expect(draft.author.isEmpty)
        #expect(draft.format == .epub)
    }

    @Test
    func draftDerivesMarkdownTitleFromFilename() throws {
        let source = try makeSourceFile(named: "Notes.markdown")
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }

        let draft = try ImportService(fileStore: TestBookFileStore()).draft(for: source)

        #expect(draft.title == "Notes")
        #expect(draft.format == .markdown)
    }

    @Test
    func draftDoesNotStoreFile() throws {
        let source = try makeSourceFile(named: "Dune.epub")
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }
        let store = TestBookFileStore()

        _ = try ImportService(fileStore: store).draft(for: source)

        #expect(store.storedSources.isEmpty)
    }

    @Test
    func confirmCreatesEntryFromConfirmedValues() async throws {
        let source = try makeEpub()
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }
        let store = TestBookFileStore()
        var draft = try ImportService(fileStore: store).draft(for: source)
        draft.title = "Dune (Revised)"
        draft.author = "Frank Herbert"

        let entry = try await ImportService(fileStore: store).confirm(draft)

        #expect(entry.title == "Dune (Revised)")
        #expect(entry.author == "Frank Herbert")
        #expect(entry.format == .epub)
        #expect(store.storedSources[entry.id] != source)
        #expect(store.storedData[entry.id] == (try Data(contentsOf: source)))
    }

    @Test
    func confirmStoresEmptyAuthorAsNoAuthor() async throws {
        let source = try makeEpub(author: nil)
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }
        let store = TestBookFileStore()
        let draft = try ImportService(fileStore: store).draft(for: source)

        let entry = try await ImportService(fileStore: store).confirm(draft)

        #expect(entry.author == nil)
    }

    @Test
    func confirmsMarkdownTitledFromFilename() async throws {
        let source = try makeSourceFile(
            named: "Notes.markdown",
            contents: Data("# Notes\n\nBody.".utf8)
        )
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }
        let store = TestBookFileStore()
        let draft = try ImportService(fileStore: store).draft(for: source)

        let entry = try await ImportService(fileStore: store).confirm(draft)

        #expect(entry.title == "Notes")
        #expect(entry.format == .markdown)
        #expect(entry.author == nil)
    }

    @Test
    func revisePreservesIdentityAndTakesEditedValuesFromDraft() throws {
        let source = try makeSourceFile(named: "Dune.epub")
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }
        let service = ImportService(fileStore: TestBookFileStore())
        var draft = try service.draft(for: source)
        draft.title = "Dune (Revised)"
        draft.author = "Frank Herbert"
        let importedAt = Date(timeIntervalSince1970: 1_700_000_000)
        let entry = LibraryEntry(
            title: "Dune",
            format: .epub,
            importedAt: importedAt
        )

        let revised = service.revise(entry, with: draft)

        #expect(revised.id == entry.id)
        #expect(revised.format == entry.format)
        #expect(revised.importedAt == entry.importedAt)
        #expect(revised.title == "Dune (Revised)")
        #expect(revised.author == "Frank Herbert")
    }

    @Test
    func reviseStoresEmptyAuthorAsNoAuthor() throws {
        let source = try makeSourceFile(named: "Dune.epub")
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }
        let service = ImportService(fileStore: TestBookFileStore())
        let draft = try service.draft(for: source)
        let entry = LibraryEntry(title: "Dune", author: "Frank Herbert", format: .epub)

        let revised = service.revise(entry, with: draft)

        #expect(revised.author == nil)
    }

    @Test
    func importsSymlinkContentsIntoLibrary() async throws {
        let target = try makeEpub(named: "Actual.epub")
        defer { try? FileManager.default.removeItem(at: target.deletingLastPathComponent()) }
        let sourceDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(
            at: sourceDirectory, withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: sourceDirectory) }
        let source = sourceDirectory.appendingPathComponent("Dune.epub")
        try FileManager.default.createSymbolicLink(at: source, withDestinationURL: target)
        let storageDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: storageDirectory) }
        let expectedData = try Data(contentsOf: target)

        let service = ImportService(
            fileStore: FileBookFileStore(directoryURL: storageDirectory)
        )
        let entry = try await service.confirm(service.draft(for: source))

        let storedFile =
            storageDirectory
            .appendingPathComponent(entry.id.uuidString, isDirectory: true)
            .appendingPathComponent("Dune.epub")
        try FileManager.default.removeItem(at: target)
        #expect(try Data(contentsOf: storedFile) == expectedData)
    }

    @Test
    func importedEntrySurvivesReopeningRepository() async throws {
        let source = try makeEpub()
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let documentURL = directory.appendingPathComponent("library.json")
        let library = LibraryStore(repository: FileLibraryRepository(documentURL: documentURL))

        let service = ImportService(fileStore: TestBookFileStore())
        let entry = try await service.confirm(service.draft(for: source))
        try library.upsert(entry)

        let reopened = LibraryStore(repository: FileLibraryRepository(documentURL: documentURL))
        try reopened.reload()
        #expect(reopened.entries == [entry])
    }

    @Test
    func storeFailureLeavesNoEntry() async throws {
        let source = try makeEpub()
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }
        let store = TestBookFileStore()
        store.shouldFail = true
        let service = ImportService(fileStore: store)

        await #expect(throws: (any Error).self) {
            _ = try await service.confirm(service.draft(for: source))
        }
        #expect(store.storedSources.isEmpty)
    }

    @Test
    func unsupportedFileIsRejectedWithoutStoring() throws {
        let source = try makeSourceFile(named: "Notes.pdf", contents: Data("book".utf8))
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }
        let store = TestBookFileStore()

        #expect(throws: ImportError.self) {
            _ = try ImportService(fileStore: store).draft(for: source)
        }
        #expect(store.storedSources.isEmpty)
    }

    @Test
    func malformedEpubIsRejectedWithoutStoring() async throws {
        let source = try makeSourceFile(
            named: "Broken.epub",
            contents: Data(repeating: 0x41, count: 64)
        )
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }
        let store = TestBookFileStore()

        await #expect(throws: ImportError.unreadableFile) {
            let service = ImportService(fileStore: store)
            _ = try await service.confirm(service.draft(for: source))
        }
        #expect(store.storedSources.isEmpty)
    }

    @Test
    func malformedMarkdownIsRejectedWithoutStoring() async throws {
        let source = try makeSourceFile(
            named: "Broken.md",
            contents: Data([0xFF, 0xFE, 0xFF])
        )
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }
        let store = TestBookFileStore()

        await #expect(throws: ImportError.unreadableFile) {
            let service = ImportService(fileStore: store)
            _ = try await service.confirm(service.draft(for: source))
        }
        #expect(store.storedSources.isEmpty)
    }

    @Test
    func missingFileIsRejectedWithoutStoring() async throws {
        let source = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("epub")
        let store = TestBookFileStore()

        await #expect(throws: ImportError.unreadableFile) {
            let service = ImportService(fileStore: store)
            _ = try await service.confirm(service.draft(for: source))
        }
        #expect(store.storedSources.isEmpty)
    }
}
