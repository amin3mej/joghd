import Foundation
import Testing

@testable import Joghd

@MainActor
struct ImportServiceTests {
    private func makeSourceFile(named name: String, contents: Data) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(name)
        try contents.write(to: url)
        return url
    }

    private func makeEpub(named name: String = "Dune.epub") throws -> URL {
        let data = EpubFixture.zip {
            ("META-INF/container.xml", EpubFixture.container)
            (
                "OEBPS/content.opf",
                EpubFixture.package(manifest: [(id: "a", href: "a.xhtml")], spine: ["a"])
            )
            ("OEBPS/a.xhtml", EpubFixture.chapter(title: "A", body: "<p>Body</p>"))
        }
        return try makeSourceFile(named: name, contents: data)
    }

    @Test
    func importsEntryTitledFromFilename() async throws {
        let source = try makeEpub()
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }
        let store = TestBookFileStore()

        let entry = try await ImportService(fileStore: store).importFile(at: source)

        #expect(entry.title == "Dune")
        #expect(entry.format == .epub)
        #expect(store.storedSources[entry.id] == source)
    }

    @Test
    func importsMarkdownTitledFromFilename() async throws {
        let source = try makeSourceFile(
            named: "Notes.markdown",
            contents: Data("# Notes\n\nBody.".utf8)
        )
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }

        let entry = try await ImportService(fileStore: TestBookFileStore()).importFile(at: source)

        #expect(entry.title == "Notes")
        #expect(entry.format == .markdown)
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

        let entry = try await ImportService(fileStore: TestBookFileStore()).importFile(at: source)
        try library.add(entry)

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

        await #expect(throws: (any Error).self) {
            _ = try await ImportService(fileStore: store).importFile(at: source)
        }
        #expect(store.storedSources.isEmpty)
    }

    @Test
    func unsupportedFileIsRejectedWithoutStoring() async throws {
        let source = try makeSourceFile(named: "Notes.pdf", contents: Data("book".utf8))
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }
        let store = TestBookFileStore()

        await #expect(throws: ImportError.self) {
            _ = try await ImportService(fileStore: store).importFile(at: source)
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
            _ = try await ImportService(fileStore: store).importFile(at: source)
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
            _ = try await ImportService(fileStore: store).importFile(at: source)
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
            _ = try await ImportService(fileStore: store).importFile(at: source)
        }
        #expect(store.storedSources.isEmpty)
    }
}
