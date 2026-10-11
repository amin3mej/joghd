import Foundation
import Testing

@testable import Joghd

@MainActor
struct ReaderStoreTests {
    @Test
    func opensAMarkdownEntry() async throws {
        let source = try makeSourceFile(named: "Notes.md", contents: "# Chapter\n\nBody.")
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }
        let entry = LibraryEntry(title: "Notes", format: .markdown)
        let fileStore = TestBookFileStore()
        _ = try await fileStore.store(source, for: entry)

        let store = ReaderStore(entry: entry, fileStore: fileStore)
        await store.load()

        guard case .loaded(let document) = store.state else {
            Issue.record("Expected the markdown entry to open")
            return
        }
        #expect(document.chapters.map(\.title) == ["Chapter"])
    }

    @Test
    func opensAnEpubEntry() async throws {
        let data = EpubFixture.zip {
            ("META-INF/container.xml", EpubFixture.container)
            (
                "OEBPS/content.opf",
                EpubFixture.package(
                    title: "A Book",
                    author: "An Author",
                    manifest: [(id: "c", href: "c.xhtml")],
                    spine: ["c"]
                )
            )
            ("OEBPS/c.xhtml", EpubFixture.chapter(title: "One", body: "<p>Hello</p>"))
        }
        let source = try makeSourceFile(named: "Book.epub", data: data)
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }
        let entry = LibraryEntry(title: "Book", format: .epub)
        let fileStore = TestBookFileStore()
        _ = try await fileStore.store(source, for: entry)

        let store = ReaderStore(entry: entry, fileStore: fileStore)
        await store.load()

        guard case .loaded(let document) = store.state else {
            Issue.record("Expected the epub entry to open")
            return
        }
        #expect(document.title == "A Book")
    }

    @Test
    func reportsFailureWhenTheStoredFileIsGone() async {
        let store = ReaderStore(
            entry: LibraryEntry(title: "Gone", format: .epub),
            fileStore: TestBookFileStore()
        )

        await store.load()

        guard case .failed = store.state else {
            Issue.record("Expected the reader to report a failure")
            return
        }
    }

    @Test
    func reportsFailureForAnUnsupportedFormat() async throws {
        let source = try makeSourceFile(named: "Paper.pdf", contents: "%PDF-1.4")
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }
        let entry = LibraryEntry(title: "Paper", format: .pdf)
        let fileStore = TestBookFileStore()
        _ = try await fileStore.store(source, for: entry)

        let store = ReaderStore(entry: entry, fileStore: fileStore)
        await store.load()

        guard case .failed = store.state else {
            Issue.record("Expected the reader to reject the PDF")
            return
        }
    }

    private func makeSourceFile(named name: String, contents: String) throws -> URL {
        try makeSourceFile(named: name, data: Data(contents.utf8))
    }

    private func makeSourceFile(named name: String, data: Data) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(name)
        try data.write(to: url)
        return url
    }
}
