import Foundation
import Testing

@testable import Joghd

struct MarkdownBookParserContentTests {
    private let parser = MarkdownBookParser()

    @Test
    func consecutiveQuoteLinesBecomeOneQuoteBlock() {
        let document = parser.parse("> Line one\n> line two")

        #expect(document.chapters[0].blocks == blocks(.quote(InlineText("Line one line two"))))
    }

    @Test
    func quotesSeparatedByABlankLineAreSeparateBlocks() {
        let document = parser.parse("> One\n\n> Two")

        let expected = blocks(
            .quote(InlineText("One")),
            .quote(InlineText("Two"))
        )
        #expect(document.chapters[0].blocks == expected)
    }

    @Test
    func unorderedListItemsBecomeListBlocks() {
        let document = parser.parse("- First\n- Second")

        let expected = blocks(
            .listItem(InlineText("First")),
            .listItem(InlineText("Second"))
        )
        #expect(document.chapters[0].blocks == expected)
    }

    @Test
    func orderedListItemsBecomeListBlocks() {
        let document = parser.parse("1. One\n2. Two")

        let expected = blocks(
            .listItem(InlineText("One")),
            .listItem(InlineText("Two"))
        )
        #expect(document.chapters[0].blocks == expected)
    }

    @Test
    func fencedCodeBecomesACodeBlockKeptVerbatim() {
        let document = parser.parse("```\nlet x = **1**\n```")

        #expect(document.chapters[0].blocks == blocks(.codeBlock("let x = **1**")))
    }

    @Test
    func codeBlockIgnoresTheOtherFenceCharacter() {
        let document = parser.parse("```\ncode\n~~~\nmore\n```")

        #expect(document.chapters[0].blocks == blocks(.codeBlock("code\n~~~\nmore")))
    }

    @Test
    func codeBlockKeepsAShorterFenceRunInside() {
        let document = parser.parse("````\n```swift\nlet x = 1\n```\n````")

        #expect(document.chapters[0].blocks == blocks(.codeBlock("```swift\nlet x = 1\n```")))
    }

    @Test
    func codeBlockKeepsAFenceLineWithAnInfoString() {
        let document = parser.parse("```\n```swift\nmore\n```")

        #expect(document.chapters[0].blocks == blocks(.codeBlock("```swift\nmore")))
    }

    @Test
    func aLongerClosingFenceClosesTheCodeBlock() {
        let document = parser.parse("```\ncode\n````")

        #expect(document.chapters[0].blocks == blocks(.codeBlock("code")))
    }

    @Test
    func aClosingFenceMayHaveTrailingWhitespace() {
        let document = parser.parse("```\ncode\n```   ")

        #expect(document.chapters[0].blocks == blocks(.codeBlock("code")))
    }

    @Test
    func dividerBecomesADividerBlock() {
        let document = parser.parse("Text\n\n---\n\nMore")

        let expected = blocks(
            .paragraph(InlineText("Text")),
            .divider,
            .paragraph(InlineText("More"))
        )
        #expect(document.chapters[0].blocks == expected)
    }

    @Test
    func quotesAndListItemsCarryInlineEmphasis() {
        let document = parser.parse("> **Bold** quote\n\n- *italic* item")

        let expected = blocks(
            .quote(InlineText(runs: runs(bold("Bold"), plain(" quote")))),
            .listItem(InlineText(runs: runs(italic("italic"), plain(" item"))))
        )
        #expect(document.chapters[0].blocks == expected)
    }

    @Test
    func frontMatterSurfacesTitleAndAuthor() {
        let document = parser.parse(
            """
            ---
            title: The Book
            author: Jane Doe
            ---

            # Chapter

            Body.
            """
        )

        #expect(document.title == "The Book")
        #expect(document.author == "Jane Doe")
        #expect(document.chapters.map(\.title) == ["Chapter"])
    }

    @Test
    func frontMatterValuesMayBeQuoted() {
        let document = parser.parse(
            """
            ---
            title: "The Book"
            author: 'Jane Doe'
            ---
            """
        )

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

        let expected = blocks(
            .divider,
            .paragraph(InlineText("Intro")),
            .divider,
            .paragraph(InlineText("More"))
        )
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

    private func blocks(_ items: Block...) -> [Block] {
        items
    }

    private func runs(_ items: InlineText.Run...) -> [InlineText.Run] {
        items
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
