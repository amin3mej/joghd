import Foundation
import Testing

@testable import Joghd

struct EpubBookParserRegressionTests {
    private let parser = EpubBookParser()

    @Test
    func chapterWithoutBodyThrows() {
        let data = EpubFixture.zip {
            ("META-INF/container.xml", EpubFixture.container)
            (
                "OEBPS/content.opf",
                EpubFixture.package(manifest: [(id: "a", href: "a.xhtml")], spine: ["a"])
            )
            (
                "OEBPS/a.xhtml",
                "<html xmlns=\"http://www.w3.org/1999/xhtml\"><head></head></html>"
            )
        }

        #expect(throws: BookParsingError.malformedEpub) {
            try parser.parse(data)
        }
    }

    @Test
    func nestedListItemsBecomeSeparateBlocks() throws {
        let body =
            "<ul><li>One<ul><li>Nested<ol><li><em>Deep</em></li></ol></li></ul></li>"
            + "<li>Two</li></ul>"
        var expected: [Block] = []
        expected.append(.listItem(InlineText("One")))
        expected.append(.listItem(InlineText("Nested")))
        expected.append(.listItem(InlineText(runs: [InlineText.Run(text: "Deep", isItalic: true)])))
        expected.append(.listItem(InlineText("Two")))

        let data = EpubFixture.zip {
            ("META-INF/container.xml", EpubFixture.container)
            (
                "OEBPS/content.opf",
                EpubFixture.package(manifest: [(id: "a", href: "a.xhtml")], spine: ["a"])
            )
            ("OEBPS/a.xhtml", EpubFixture.chapter(title: "Doc", body: body))
        }
        let document = try parser.parse(data)

        #expect(document.chapters[0].blocks == expected)
    }

    @Test
    func corruptArchiveEntryThrowsMalformedEpub() {
        var data = EpubFixture.zip {
            ("META-INF/container.xml", EpubFixture.container)
            (
                "OEBPS/content.opf",
                EpubFixture.package(manifest: [(id: "a", href: "a.xhtml")], spine: ["a"])
            )
            ("OEBPS/a.xhtml", EpubFixture.chapter(title: "A", body: "<p>Body</p>"))
        }
        data[0] ^= 0xFF

        #expect(throws: BookParsingError.malformedEpub) {
            try parser.parse(data)
        }
    }

    @Test
    func ordinaryDeflatedEntriesRemainReadable() throws {
        let data = EpubFixture.zip(deflated: true) {
            ("META-INF/container.xml", EpubFixture.container)
            (
                "OEBPS/content.opf",
                EpubFixture.package(manifest: [(id: "a", href: "a.xhtml")], spine: ["a"])
            )
            ("OEBPS/a.xhtml", EpubFixture.chapter(title: "A", body: "<p>Body</p>"))
        }

        let document = try parser.parse(data)

        #expect(document.chapters[0].blocks == [.paragraph(InlineText("Body"))])
    }

    @Test
    func suspiciousCompressionRatioThrowsMalformedEpub() {
        let container = EpubFixture.container + String(repeating: " ", count: 512 * 1_024)
        let data = EpubFixture.zip(deflated: true) {
            ("META-INF/container.xml", container)
            ("OEBPS/content.opf", EpubFixture.package(manifest: [], spine: []))
        }

        #expect(throws: BookParsingError.malformedEpub) {
            try parser.parse(data)
        }
    }

    @Test
    func oversizedArchiveEntryThrowsMalformedEpub() throws {
        let container = EpubFixture.container + String(repeating: " ", count: 512 * 1_024)
        var data = EpubFixture.zip {
            ("META-INF/container.xml", container)
            ("OEBPS/content.opf", EpubFixture.package(manifest: [], spine: []))
        }
        let directory = try #require(data.range(of: Data([0x50, 0x4B, 0x01, 0x02])))
        let sizeOffset = directory.lowerBound + 24
        let oversized: UInt32 = 64 * 1_024 * 1_024 + 1
        withUnsafeBytes(of: oversized.littleEndian) { bytes in
            data.replaceSubrange(sizeOffset..<(sizeOffset + 4), with: bytes)
        }

        #expect(throws: BookParsingError.malformedEpub) {
            try parser.parse(data)
        }
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
}
