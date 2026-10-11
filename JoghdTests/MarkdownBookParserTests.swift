import Foundation
import Testing

@testable import Joghd

struct MarkdownBookParserTests {
    private let parser = MarkdownBookParser()

    // MARK: - Chapters and blocks

    @Test
    func paragraphBecomesASingleChapter() {
        let document = parser.parse("Hello world.")

        #expect(document.chapters.count == 1)
        #expect(document.chapters[0].title == nil)
        #expect(document.chapters[0].blocks == [.paragraph(InlineText("Hello world."))])
    }

    @Test
    func blankLineSeparatesParagraphs() {
        let document = parser.parse("First paragraph.\n\nSecond paragraph.")

        #expect(document.chapters[0].blocks == [
            .paragraph(InlineText("First paragraph.")),
            .paragraph(InlineText("Second paragraph.")),
        ])
    }

    @Test
    func topLevelHeadingStartsAChapterAndNamesIt() {
        let document = parser.parse("# Chapter One\n\nSome text.")

        #expect(document.chapters.count == 1)
        #expect(document.chapters[0].title == "Chapter One")
        #expect(document.chapters[0].blocks == [.paragraph(InlineText("Some text."))])
    }

    @Test
    func oneTopLevelHeadingPerChapterYieldsOneChapterPerHeading() {
        let document = parser.parse("""
        # One

        First.

        # Two

        Second.
        """)

        #expect(document.chapters.count == 2)
        #expect(document.chapters.map(\.title) == ["One", "Two"])
        #expect(document.chapters[0].blocks == [.paragraph(InlineText("First."))])
        #expect(document.chapters[1].blocks == [.paragraph(InlineText("Second."))])
    }

    @Test
    func markdownWithoutHeadingsIsASingleChapter() {
        let document = parser.parse("Just a paragraph.\n\nAnd another.")

        #expect(document.chapters.count == 1)
        #expect(document.chapters[0].title == nil)
        #expect(document.chapters[0].blocks.count == 2)
    }

    @Test
    func lowerLevelHeadingsStayAsBlocksWithinAChapter() {
        let document = parser.parse("""
        # Chapter

        ## Section

        Body.
        """)

        #expect(document.chapters.count == 1)
        #expect(document.chapters[0].title == "Chapter")
        #expect(document.chapters[0].blocks == [
            .heading(level: 2, text: InlineText("Section")),
            .paragraph(InlineText("Body.")),
        ])
    }

    @Test
    func contentBeforeTheFirstHeadingBecomesAnUntitledChapter() {
        let document = parser.parse("""
        Preamble.

        # Chapter

        Body.
        """)

        #expect(document.chapters.count == 2)
        #expect(document.chapters[0].title == nil)
        #expect(document.chapters[0].blocks == [.paragraph(InlineText("Preamble."))])
        #expect(document.chapters[1].title == "Chapter")
    }

    // MARK: - Inline emphasis

    @Test
    func boldCoversTheCorrectRun() {
        let document = parser.parse("This is **bold** text.")

        #expect(document.chapters[0].blocks == [
            .paragraph(InlineText(runs: [
                plain("This is "),
                bold("bold"),
                plain(" text."),
            ])),
        ])
    }

    @Test
    func italicCoversTheCorrectRun() {
        let document = parser.parse("This is *italic* text.")

        #expect(document.chapters[0].blocks == [
            .paragraph(InlineText(runs: [
                plain("This is "),
                italic("italic"),
                plain(" text."),
            ])),
        ])
    }

    @Test
    func underscoresAlsoMarkEmphasis() {
        let document = parser.parse("__bold__ and _italic_")

        #expect(document.chapters[0].blocks == [
            .paragraph(InlineText(runs: [
                bold("bold"),
                plain(" and "),
                italic("italic"),
            ])),
        ])
    }

    @Test
    func tripleMarkerMarksBoldAndItalic() {
        let document = parser.parse("***both***")

        #expect(document.chapters[0].blocks == [
            .paragraph(InlineText(runs: [boldItalic("both")])),
        ])
    }

    @Test
    func emphasisRunsInterleaveWithPlainText() {
        let document = parser.parse("a **b** c *d* e")

        #expect(document.chapters[0].blocks == [
            .paragraph(InlineText(runs: [
                plain("a "),
                bold("b"),
                plain(" c "),
                italic("d"),
                plain(" e"),
            ])),
        ])
    }

    @Test
    func intrawordUnderscoresAreNotEmphasis() {
        let document = parser.parse("snake_case_name")

        #expect(document.chapters[0].blocks == [
            .paragraph(InlineText("snake_case_name")),
        ])
    }

    @Test
    func linkKeepsTextAndDropsTarget() {
        let document = parser.parse("See [the docs](https://example.com) now.")

        #expect(document.chapters[0].blocks == [
            .paragraph(InlineText("See the docs now.")),
        ])
    }

    @Test
    func imageIsNotRepresented() {
        let document = parser.parse("A![alt text](img.png)B")

        #expect(document.chapters[0].blocks == [
            .paragraph(InlineText("AB")),
        ])
    }

    @Test
    func footnoteTargetIsNotRepresented() {
        let document = parser.parse("Text[^1] more")

        #expect(document.chapters[0].blocks == [
            .paragraph(InlineText("Text more")),
        ])
    }

    // MARK: - Quotes, lists, code, dividers

    @Test
    func consecutiveQuoteLinesBecomeOneQuoteBlock() {
        let document = parser.parse("> Line one\n> line two")

        #expect(document.chapters[0].blocks == [
            .quote(InlineText("Line one line two")),
        ])
    }

    @Test
    func quotesSeparatedByABlankLineAreSeparateBlocks() {
        let document = parser.parse("> One\n\n> Two")

        #expect(document.chapters[0].blocks == [
            .quote(InlineText("One")),
            .quote(InlineText("Two")),
        ])
    }

    @Test
    func unorderedListItemsBecomeListBlocks() {
        let document = parser.parse("- First\n- Second")

        #expect(document.chapters[0].blocks == [
            .listItem(InlineText("First")),
            .listItem(InlineText("Second")),
        ])
    }

    @Test
    func orderedListItemsBecomeListBlocks() {
        let document = parser.parse("1. One\n2. Two")

        #expect(document.chapters[0].blocks == [
            .listItem(InlineText("One")),
            .listItem(InlineText("Two")),
        ])
    }

    @Test
    func fencedCodeBecomesACodeBlockKeptVerbatim() {
        let document = parser.parse("```\nlet x = **1**\n```")

        #expect(document.chapters[0].blocks == [
            .codeBlock("let x = **1**"),
        ])
    }

    @Test
    func dividerBecomesADividerBlock() {
        let document = parser.parse("Text\n\n---\n\nMore")

        #expect(document.chapters[0].blocks == [
            .paragraph(InlineText("Text")),
            .divider,
            .paragraph(InlineText("More")),
        ])
    }

    @Test
    func quotesAndListItemsCarryInlineEmphasis() {
        let document = parser.parse("> **Bold** quote\n\n- *italic* item")

        #expect(document.chapters[0].blocks == [
            .quote(InlineText(runs: [bold("Bold"), plain(" quote")])),
            .listItem(InlineText(runs: [italic("italic"), plain(" item")])),
        ])
    }

    // MARK: - Front matter

    @Test
    func frontMatterSurfacesTitleAndAuthor() {
        let document = parser.parse("""
        ---
        title: The Book
        author: Jane Doe
        ---

        # Chapter

        Body.
        """)

        #expect(document.title == "The Book")
        #expect(document.author == "Jane Doe")
        #expect(document.chapters.map(\.title) == ["Chapter"])
    }

    @Test
    func frontMatterValuesMayBeQuoted() {
        let document = parser.parse("""
        ---
        title: "The Book"
        author: 'Jane Doe'
        ---
        """)

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

        #expect(document.title == nil)
        #expect(document.chapters[0].blocks == [
            .divider,
            .paragraph(InlineText("Intro")),
            .divider,
            .paragraph(InlineText("More")),
        ])
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

    // MARK: - Reading a file

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

    // MARK: - Helpers

    private func plain(_ string: String) -> InlineText.Run {
        InlineText.Run(text: string)
    }

    private func bold(_ string: String) -> InlineText.Run {
        InlineText.Run(text: string, isBold: true)
    }

    private func italic(_ string: String) -> InlineText.Run {
        InlineText.Run(text: string, isItalic: true)
    }

    private func boldItalic(_ string: String) -> InlineText.Run {
        InlineText.Run(text: string, isBold: true, isItalic: true)
    }
}
