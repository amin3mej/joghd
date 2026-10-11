import Foundation
import Testing

@testable import Joghd

struct EpubBookParserTests {
    private let parser = EpubBookParser()

    @Test
    func sampleEpubSurfacesTitleAndAuthor() throws {
        let document = try parser.parse(contentsOf: sampleURL())

        #expect(document.title == "A Tiny Book")
        #expect(document.author == "Ada Lovelace")
    }

    @Test
    func sampleEpubYieldsOneChapterPerSpineDocumentInSpineOrder() throws {
        let document = try parser.parse(contentsOf: sampleURL())
        let titles = document.chapters.map(\.title)

        #expect(titles == ["First Chapter", "Second Chapter", "Third Chapter"])
    }

    @Test
    func sampleEpubMapsXHTMLBlocksAndInlineEmphasis() throws {
        let document = try parser.parse(contentsOf: sampleURL())
        let chapter = try #require(document.chapters.first)
        var runs: [InlineText.Run] = []
        runs.append(plain("Alpha with "))
        runs.append(italic("italic"))
        runs.append(plain(" and "))
        runs.append(bold("bold"))
        runs.append(plain("."))
        var expected: [Block] = []
        expected.append(.heading(level: 1, text: InlineText("First Chapter")))
        expected.append(.paragraph(InlineText(runs: runs)))
        expected.append(.quote(InlineText("A quoted line.")))
        expected.append(.listItem(InlineText("One")))
        expected.append(.listItem(InlineText("Two")))

        #expect(chapter.blocks == expected)
    }

    @Test
    func spineOrderFollowsItemrefsNotManifestOrder() throws {
        let data = EpubFixture.zip {
            ("META-INF/container.xml", EpubFixture.container)
            (
                "OEBPS/content.opf",
                EpubFixture.package(
                    manifest: [(id: "b", href: "b.xhtml"), (id: "a", href: "a.xhtml")],
                    spine: ["a", "b"]
                )
            )
            ("OEBPS/a.xhtml", EpubFixture.chapter(title: "A", body: "<p>First</p>"))
            ("OEBPS/b.xhtml", EpubFixture.chapter(title: "B", body: "<p>Second</p>"))
        }

        let document = try parser.parse(data)

        #expect(document.chapters.map(\.title) == ["A", "B"])
    }

    @Test
    func missingTitleAndAuthorStayAbsent() throws {
        let data = EpubFixture.zip {
            ("META-INF/container.xml", EpubFixture.container)
            (
                "OEBPS/content.opf",
                EpubFixture.package(
                    title: nil,
                    author: nil,
                    manifest: [(id: "a", href: "a.xhtml")],
                    spine: ["a"]
                )
            )
            ("OEBPS/a.xhtml", EpubFixture.chapter(title: nil, body: "<p>Body</p>"))
        }

        let document = try parser.parse(data)

        #expect(document.title == nil)
        #expect(document.author == nil)
        #expect(document.chapters[0].title == nil)
    }

    @Test
    func headingsOfEveryLevelBecomeHeadingBlocks() throws {
        let body = "<h1>One</h1><h3>Three</h3><h6>Six</h6>"
        var expected: [Block] = []
        expected.append(.heading(level: 1, text: InlineText("One")))
        expected.append(.heading(level: 3, text: InlineText("Three")))
        expected.append(.heading(level: 6, text: InlineText("Six")))

        let document = try parseSingleChapter(body: body, title: "Doc")

        #expect(document.chapters[0].blocks == expected)
    }

    @Test
    func nestedContainersAreWalkedInOrder() throws {
        let body = "<div><section><p>One</p></section><p>Two</p></div>"
        var expected: [Block] = []
        expected.append(.paragraph(InlineText("One")))
        expected.append(.paragraph(InlineText("Two")))

        let document = try parseSingleChapter(body: body, title: "Doc")

        #expect(document.chapters[0].blocks == expected)
    }

    @Test
    func nestedEmphasisCombinesBoldAndItalic() throws {
        let body = "<p>a <strong>bold <em>and italic</em></strong> b</p>"
        var runs: [InlineText.Run] = []
        runs.append(plain("a "))
        runs.append(bold("bold "))
        runs.append(InlineText.Run(text: "and italic", isBold: true, isItalic: true))
        runs.append(plain(" b"))

        let document = try parseSingleChapter(body: body, title: "Doc")

        #expect(document.chapters[0].blocks == [.paragraph(InlineText(runs: runs))])
    }

    @Test
    func sourceWhitespaceIsCollapsed() throws {
        let body = "<p>\n      Alpha   beta\n    </p>"

        let document = try parseSingleChapter(body: body, title: "Doc")

        #expect(document.chapters[0].blocks == [.paragraph(InlineText("Alpha beta"))])
    }

    @Test
    func dataThatIsNotAZipThrows() {
        let garbage = Data(repeating: 0x41, count: 128)

        #expect(throws: (any Error).self) {
            try parser.parse(garbage)
        }
    }

    @Test
    func epubWithoutAContainerThrows() {
        let data = EpubFixture.zip {
            ("OEBPS/content.opf", EpubFixture.package(manifest: [], spine: []))
        }

        #expect(throws: (any Error).self) {
            try parser.parse(data)
        }
    }

    @Test
    func containerPointingAtAMissingPackageThrows() {
        let data = EpubFixture.zip {
            ("META-INF/container.xml", EpubFixture.container)
        }

        #expect(throws: (any Error).self) {
            try parser.parse(data)
        }
    }

    @Test
    func spineReferencingAnUnknownManifestItemThrows() {
        let data = EpubFixture.zip {
            ("META-INF/container.xml", EpubFixture.container)
            (
                "OEBPS/content.opf",
                EpubFixture.package(manifest: [(id: "a", href: "a.xhtml")], spine: ["a", "ghost"])
            )
            ("OEBPS/a.xhtml", EpubFixture.chapter(title: "A", body: "<p>Body</p>"))
        }

        #expect(throws: (any Error).self) {
            try parser.parse(data)
        }
    }

    @Test
    func spineDocumentMissingFromTheArchiveThrows() {
        let data = EpubFixture.zip {
            ("META-INF/container.xml", EpubFixture.container)
            (
                "OEBPS/content.opf",
                EpubFixture.package(manifest: [(id: "a", href: "a.xhtml")], spine: ["a"])
            )
        }

        #expect(throws: (any Error).self) {
            try parser.parse(data)
        }
    }

    @Test
    func malformedXHTMLThrows() {
        let data = EpubFixture.zip {
            ("META-INF/container.xml", EpubFixture.container)
            (
                "OEBPS/content.opf",
                EpubFixture.package(manifest: [(id: "a", href: "a.xhtml")], spine: ["a"])
            )
            ("OEBPS/a.xhtml", "<html><body><p>Unclosed")
        }

        #expect(throws: (any Error).self) {
            try parser.parse(data)
        }
    }

    @Test
    func chapterHrefsResolveRelativeToThePackageDirectory() throws {
        let opf = EpubFixture.package(manifest: [(id: "a", href: "Text/../a.xhtml")], spine: ["a"])
        let data = EpubFixture.zip {
            ("META-INF/container.xml", EpubFixture.container)
            ("OEBPS/content.opf", opf)
            ("OEBPS/a.xhtml", EpubFixture.chapter(title: "A", body: "<p>Body</p>"))
        }

        let document = try parser.parse(data)

        #expect(document.chapters.count == 1)
        #expect(document.chapters[0].title == "A")
    }

    @Test
    func nonLinearSpineItemsAreNotChapters() throws {
        let opf = EpubFixture.package(
            manifest: [(id: "a", href: "a.xhtml"), (id: "b", href: "b.xhtml")],
            spine: ["a", "b"],
            nonLinear: ["b"]
        )
        let data = EpubFixture.zip {
            ("META-INF/container.xml", EpubFixture.container)
            ("OEBPS/content.opf", opf)
            ("OEBPS/a.xhtml", EpubFixture.chapter(title: "A", body: "<p>First</p>"))
            ("OEBPS/b.xhtml", EpubFixture.chapter(title: "B", body: "<p>Second</p>"))
        }

        let document = try parser.parse(data)

        #expect(document.chapters.map(\.title) == ["A"])
    }

    @Test
    func spineItemrefWithoutAnIdrefThrows() {
        let opf =
            "<package><manifest><item id=\"a\" href=\"a.xhtml\"/></manifest>"
            + "<spine><itemref/></spine></package>"
        let data = EpubFixture.zip {
            ("META-INF/container.xml", EpubFixture.container)
            ("OEBPS/content.opf", opf)
        }

        #expect(throws: (any Error).self) {
            try parser.parse(data)
        }
    }

    private func parseSingleChapter(body: String, title: String?) throws -> BookDocument {
        let data = EpubFixture.zip {
            ("META-INF/container.xml", EpubFixture.container)
            (
                "OEBPS/content.opf",
                EpubFixture.package(manifest: [(id: "a", href: "a.xhtml")], spine: ["a"])
            )
            ("OEBPS/a.xhtml", EpubFixture.chapter(title: title, body: body))
        }
        return try parser.parse(data)
    }

    private func sampleURL() throws -> URL {
        let bundle = Bundle(for: EpubFixture.BundleToken.self)
        return try #require(bundle.url(forResource: "sample", withExtension: "epub"))
    }

    private func plain(_ string: String) -> InlineText.Run {
        InlineText.Run(text: string)
    }

    private func bold(_ string: String) -> InlineText.Run {
        InlineText.Run(text: string, isBold: true)
    }

    private func italic(_ string: String) -> InlineText.Run {
        InlineText.Run(text: string, isItalic: true)
    }
}
