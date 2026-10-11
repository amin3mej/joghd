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
    func importsEntryTitledFromFilename() throws {
        let source = try makeSourceFile(named: "Dune.epub")
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }
        let store = TestBookFileStore()

        let entry = try ImportService(fileStore: store).importFile(at: source)

        #expect(entry.title == "Dune")
        #expect(entry.format == .epub)
        #expect(store.storedSources[entry.id] == source)
    }

    @Test
    func importsMarkdownTitledFromFilename() throws {
        let source = try makeSourceFile(named: "Notes.markdown")
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }

        let entry = try ImportService(fileStore: TestBookFileStore()).importFile(at: source)

        #expect(entry.title == "Notes")
        #expect(entry.format == .markdown)
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

        let entry = try ImportService(fileStore: TestBookFileStore()).importFile(at: source)
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

        #expect(throws: (any Error).self) {
            _ = try ImportService(fileStore: store).importFile(at: source)
        }
        #expect(store.storedSources.isEmpty)
    }

    @Test
    func unsupportedFileIsRejected() throws {
        let source = try makeSourceFile(named: "Notes.pdf")
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }
        let store = TestBookFileStore()

        #expect(throws: ImportError.self) {
            _ = try ImportService(fileStore: store).importFile(at: source)
        }
        #expect(store.storedSources.isEmpty)
    }
}
