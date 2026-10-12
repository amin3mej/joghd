import Foundation
import Testing

@testable import Joghd

@MainActor
struct ImportServiceCoverTests {
    @Test
    func confirmPersistsAnEmbeddedCoverThumbnail() async throws {
        let source = try coverEpub(
            resources: [("OEBPS/cover.png", CoverFixture.imageData(width: 400, height: 600))]
        )
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }
        let service = ImportService(fileStore: TestBookFileStore())

        let entry = try await service.confirm(try await service.draft(for: source))

        let stored = try #require(entry.coverImageData)
        #expect(CoverFixture.pixelSize(of: stored) != nil)
    }

    @Test
    func confirmFallsBackToGeneratedCoverWhenTheCoverImageIsUnreadable() async throws {
        let source = try coverEpub(resources: [("OEBPS/cover.png", Data("not an image".utf8))])
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }
        let store = TestBookFileStore()
        let service = ImportService(fileStore: store)

        let entry = try await service.confirm(try await service.draft(for: source))

        #expect(entry.coverImageData == nil)
        #expect(entry.title == "The Book")
        #expect(store.storedData[entry.id] != nil)
    }

    @Test
    func confirmFallsBackWhenTheCoverResourceIsMissing() async throws {
        let source = try TestFiles.source(
            named: "Cover.epub",
            contents: EpubCoverFixture.epub(
                manifest: [(id: "a", href: "a.xhtml"), (id: "cover", href: "missing.png")],
                properties: ["cover": "cover-image"]
            )
        )
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }
        let store = TestBookFileStore()
        let service = ImportService(fileStore: store)

        let entry = try await service.confirm(try await service.draft(for: source))

        #expect(entry.coverImageData == nil)
        #expect(store.storedSources[entry.id] != nil)
    }

    @Test
    func markdownImportKeepsTheGeneratedCover() async throws {
        let source = try TestFiles.source(
            named: "Notes.markdown",
            contents: Data("# Notes\n\nBody.".utf8)
        )
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }
        let service = ImportService(fileStore: TestBookFileStore())

        let entry = try await service.confirm(try await service.draft(for: source))

        #expect(entry.coverImageData == nil)
        #expect(entry.format == .markdown)
    }

    @Test
    func embeddedCoverSurvivesReopeningRepository() async throws {
        let source = try coverEpub(
            resources: [("OEBPS/cover.png", CoverFixture.imageData(width: 400, height: 600))]
        )
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let documentURL = directory.appendingPathComponent("library.json")
        let library = LibraryStore(
            repository: FileLibraryRepository(documentURL: documentURL),
            fileStore: TestBookFileStore()
        )
        let service = ImportService(fileStore: TestBookFileStore())
        let entry = try await service.confirm(try await service.draft(for: source))
        try library.upsert(entry)

        let reopened = LibraryStore(
            repository: FileLibraryRepository(documentURL: documentURL),
            fileStore: TestBookFileStore()
        )
        try reopened.reload()

        #expect(reopened.entries == [entry])
        #expect(reopened.entries.first?.coverImageData != nil)
    }

    private func coverEpub(resources: [(String, Data)]) throws -> URL {
        try TestFiles.source(
            named: "Cover.epub",
            contents: EpubCoverFixture.epub(
                manifest: [(id: "a", href: "a.xhtml"), (id: "cover", href: "cover.png")],
                properties: ["cover": "cover-image"],
                resources: resources
            )
        )
    }
}
