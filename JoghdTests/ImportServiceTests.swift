import Foundation
import Testing

@testable import Joghd

@MainActor
struct ImportServiceTests {
    private func makeSourceFile(named name: String) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(name)
        try Data("book".utf8).write(to: url)
        return url
    }

    @Test
    func draftDerivesTitleAndFormatFromFilename() throws {
        let source = try makeSourceFile(named: "Dune.epub")
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }

        let draft = try ImportService(fileStore: TestBookFileStore()).draft(for: source)

        #expect(draft.title == "Dune")
        #expect(draft.author.isEmpty)
        #expect(draft.format == .epub)
        #expect(draft.source == source)
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
    func cancelStoresNoFileAndCreatesNoEntry() throws {
        let source = try makeSourceFile(named: "Dune.epub")
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }
        let store = TestBookFileStore()

        _ = try ImportService(fileStore: store).draft(for: source)

        #expect(store.storedSources.isEmpty)
    }

    @Test
    func confirmCreatesEntryFromConfirmedValues() throws {
        let source = try makeSourceFile(named: "Dune.epub")
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }
        let store = TestBookFileStore()
        var draft = try ImportService(fileStore: store).draft(for: source)
        draft.title = "Dune (Revised)"
        draft.author = "Frank Herbert"

        let entry = try ImportService(fileStore: store).confirm(draft)

        #expect(entry.title == "Dune (Revised)")
        #expect(entry.author == "Frank Herbert")
        #expect(entry.format == .epub)
        #expect(store.storedSources[entry.id] == source)
    }

    @Test
    func confirmStoresEmptyAuthorAsNoAuthor() throws {
        let source = try makeSourceFile(named: "Dune.epub")
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }
        let store = TestBookFileStore()
        let draft = try ImportService(fileStore: store).draft(for: source)

        let entry = try ImportService(fileStore: store).confirm(draft)

        #expect(entry.author == nil)
    }

    @Test
    func importedEntrySurvivesReopeningRepository() throws {
        let source = try makeSourceFile(named: "Dune.epub")
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let documentURL = directory.appendingPathComponent("library.json")
        let library = LibraryStore(repository: FileLibraryRepository(documentURL: documentURL))

        let service = ImportService(fileStore: TestBookFileStore())
        let entry = try service.confirm(service.draft(for: source))
        try library.add(entry)

        let reopened = LibraryStore(repository: FileLibraryRepository(documentURL: documentURL))
        try reopened.reload()
        #expect(reopened.entries == [entry])
    }

    @Test
    func storeFailureLeavesNoEntry() throws {
        let source = try makeSourceFile(named: "Dune.epub")
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }
        let store = TestBookFileStore()
        store.shouldFail = true
        let service = ImportService(fileStore: store)

        #expect(throws: (any Error).self) {
            _ = try service.confirm(service.draft(for: source))
        }
        #expect(store.storedSources.isEmpty)
    }

    @Test
    func unsupportedFileIsRejected() throws {
        let source = try makeSourceFile(named: "Notes.pdf")
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }
        let store = TestBookFileStore()

        #expect(throws: ImportError.self) {
            _ = try ImportService(fileStore: store).draft(for: source)
        }
        #expect(store.storedSources.isEmpty)
    }
}
