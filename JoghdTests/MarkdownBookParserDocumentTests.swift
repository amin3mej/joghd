import Foundation
import Testing

@testable import Joghd

struct MarkdownBookParserDocumentTests {
    private let parser = MarkdownBookParser()

    @Test
    func consecutiveQuoteLinesBecomeOneQuoteBlock() {
        let document = parser.parse("> Line one\n> line two")

        #expect(document.chapters[0].blocks == [.quote(InlineText("Line one line two"))])
    }

    @Test
    func quotesSeparatedByABlankLineAreSeparateBlocks() {
        let document = parser.parse("> One\n\n> Two")
        var expected: [Block] = []
        expected.append(.quote(InlineText("One")))
        expected.append(.quote(InlineText("Two")))

        #expect(document.chapters[0].blocks == expected)
    }

    @Test
    func unorderedListItemsBecomeListBlocks() {
        let document = parser.parse("- First\n- Second")
        var expected: [Block] = []
        expected.append(.listItem(InlineText("First")))
        expected.append(.listItem(InlineText("Second")))

        #expect(document.chapters[0].blocks == expected)
    }

    @Test
    func orderedListItemsBecomeListBlocks() {
        let document = parser.parse("1. One\n2. Two")
        var expected: [Block] = []
        expected.append(.listItem(InlineText("One")))
        expected.append(.listItem(InlineText("Two")))

        #expect(document.chapters[0].blocks == expected)
    }

    @Test
    func fencedCodeBecomesACodeBlockKeptVerbatim() {
        let document = parser.parse("```\nlet x = **1**\n```")

        #expect(document.chapters[0].blocks == [.codeBlock("let x = **1**")])
    }

    @Test
    func aFenceOfAnotherCharacterDoesNotCloseTheBlock() {
        let document = parser.parse("```\n~~~\n```")

        #expect(document.chapters[0].blocks == [.codeBlock("~~~")])
    }

    @Test
    func aShorterFenceDoesNotCloseTheBlock() {
        let document = parser.parse("````\n```\n````")

        #expect(document.chapters[0].blocks == [.codeBlock("```")])
    }

    @Test
    func dividerBecomesADividerBlock() {
        let document = parser.parse("Text\n\n---\n\nMore")
        var expected: [Block] = []
        expected.append(.paragraph(InlineText("Text")))
        expected.append(.divider)
        expected.append(.paragraph(InlineText("More")))

        #expect(document.chapters[0].blocks == expected)
    }

    @Test
    func frontMatterSurfacesTitleAndAuthor() {
        let markdown = """
            ---
            title: The Book
            author: Jane Doe
            ---

            # Chapter

            Body.
            """
        let document = parser.parse(markdown)

        #expect(document.title == "The Book")
        #expect(document.author == "Jane Doe")
        #expect(document.chapters.map(\.title) == ["Chapter"])
    }

    @Test
    func frontMatterValuesMayBeQuoted() {
        let markdown = """
            ---
            title: "The Book"
            author: 'Jane Doe'
            ---
            """
        let document = parser.parse(markdown)

        #expect(document.title == "The Book")
        #expect(document.author == "Jane Doe")
    }

    @Test
    func emptyDocumentIsASingleChapter() {
        let document = parser.parse("")

        #expect(document.chapters.count == 1)
        #expect(document.chapters[0].title == nil)
        #expect(document.chapters[0].blocks.isEmpty)
    }

    @Test
    func frontMatterOnlyDocumentIsASingleChapter() {
        let document = parser.parse("---\ntitle: The Book\n---")

        #expect(document.title == "The Book")
        #expect(document.chapters.count == 1)
    }

    @Test
    func documentOpeningWithADividerIsNotFrontMatter() {
        let document = parser.parse("---\nIntro\n---\n\nMore")
        var expected: [Block] = []
        expected.append(.divider)
        expected.append(.paragraph(InlineText("Intro")))
        expected.append(.divider)
        expected.append(.paragraph(InlineText("More")))

        #expect(document.title == nil)
        #expect(document.chapters[0].blocks == expected)
    }

    @Test
    func headingKeepsATrailingHashNotPrecededBySpace() {
        let document = parser.parse("# C#")

        #expect(document.chapters[0].title == "C#")
    }

    @Test
    func headingDropsAClosingHashSequence() {
        let document = parser.parse("# Title ###")

        #expect(document.chapters[0].title == "Title")
    }

    @Test
    func imageOnlyQuoteIsSkipped() {
        let document = parser.parse("> ![img](x.png)")

        #expect(document.chapters[0].blocks.isEmpty)
    }

    @Test
    func parsesMarkdownFromAFile() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString).md")
        try "# Chapter\n\nBody.".write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }

        let document = try parser.parse(contentsOf: url)

        #expect(document.chapters.map(\.title) == ["Chapter"])
        #expect(document.chapters[0].blocks == [.paragraph(InlineText("Body."))])
    }

    @Test
    func unreadableFileThrowsInsteadOfReturningAPartialDocument() {
        let missing = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString).md")

        #expect(throws: (any Error).self) {
            try parser.parse(contentsOf: missing)
        }
    }
}
