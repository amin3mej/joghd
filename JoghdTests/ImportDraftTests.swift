import Foundation
import Testing

@testable import Joghd

@MainActor
struct ImportDraftTests {
    @Test
    func draftPrefillsTitleAndAuthorFromEpubPackage() throws {
        let source = try TestFiles.epub()
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }

        let draft = try ImportService(fileStore: TestBookFileStore()).draft(for: source)

        #expect(draft.title == "The Book")
        #expect(draft.author == "The Author")
        #expect(draft.format == .epub)
        #expect(draft.source == source)
    }

    @Test
    func draftPrefillsMetadataWhenChapterCannotBeRead() throws {
        let data = EpubFixture.zip {
            ("META-INF/container.xml", EpubFixture.container)
            (
                "OEBPS/content.opf",
                EpubFixture.package(manifest: [(id: "a", href: "a.xhtml")], spine: ["a"])
            )
        }
        let source = try TestFiles.source(named: "Dune.epub", contents: data)
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }

        let draft = try ImportService(fileStore: TestBookFileStore()).draft(for: source)

        #expect(draft.title == "The Book")
        #expect(draft.author == "The Author")
    }

    @Test
    func draftPrefillsTitleAndAuthorFromMarkdownFrontMatter() throws {
        let source = try TestFiles.source(
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
        let source = try TestFiles.epub(named: "Dune.epub", title: nil, author: nil)
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }

        let draft = try ImportService(fileStore: TestBookFileStore()).draft(for: source)

        #expect(draft.title == "Dune")
        #expect(draft.author.isEmpty)
        #expect(draft.format == .epub)
    }

    @Test
    func draftDerivesMarkdownTitleFromFilename() throws {
        let source = try TestFiles.source(named: "Notes.markdown")
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }

        let draft = try ImportService(fileStore: TestBookFileStore()).draft(for: source)

        #expect(draft.title == "Notes")
        #expect(draft.format == .markdown)
    }

    @Test
    func draftDoesNotStoreFile() throws {
        let source = try TestFiles.epub()
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }
        let store = TestBookFileStore()

        _ = try ImportService(fileStore: store).draft(for: source)

        #expect(store.storedSources.isEmpty)
    }
}
