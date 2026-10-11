import Testing

@testable import Joghd

struct MarkdownBookParserTests {
    private let parser = MarkdownBookParser()

    @Test
    func paragraphBecomesASingleChapter() {
        let document = parser.parse("Hello world.")
        var expected: [Block] = []
        expected.append(.paragraph(InlineText("Hello world.")))

        #expect(document.chapters.count == 1)
        #expect(document.chapters[0].title == nil)
        #expect(document.chapters[0].blocks == expected)
    }

    @Test
    func blankLineSeparatesParagraphs() {
        let document = parser.parse("First paragraph.\n\nSecond paragraph.")
        var expected: [Block] = []
        expected.append(.paragraph(InlineText("First paragraph.")))
        expected.append(.paragraph(InlineText("Second paragraph.")))

        #expect(document.chapters[0].blocks == expected)
    }

    @Test
    func topLevelHeadingStartsAChapterAndNamesIt() {
        let document = parser.parse("# Chapter One\n\nSome text.")
        var expected: [Block] = []
        expected.append(.paragraph(InlineText("Some text.")))

        #expect(document.chapters.count == 1)
        #expect(document.chapters[0].title == "Chapter One")
        #expect(document.chapters[0].blocks == expected)
    }

    @Test
    func oneTopLevelHeadingPerChapterYieldsOneChapterPerHeading() {
        let markdown = """
            # One

            First.

            # Two

            Second.
            """
        let document = parser.parse(markdown)

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
        let markdown = """
            # Chapter

            ## Section

            Body.
            """
        let document = parser.parse(markdown)
        var expected: [Block] = []
        expected.append(.heading(level: 2, text: InlineText("Section")))
        expected.append(.paragraph(InlineText("Body.")))

        #expect(document.chapters.count == 1)
        #expect(document.chapters[0].title == "Chapter")
        #expect(document.chapters[0].blocks == expected)
    }

    @Test
    func contentBeforeTheFirstHeadingBecomesAnUntitledChapter() {
        let markdown = """
            Preamble.

            # Chapter

            Body.
            """
        let document = parser.parse(markdown)

        #expect(document.chapters.count == 2)
        #expect(document.chapters[0].title == nil)
        #expect(document.chapters[0].blocks == [.paragraph(InlineText("Preamble."))])
        #expect(document.chapters[1].title == "Chapter")
    }

    @Test
    func boldCoversTheCorrectRun() {
        let document = parser.parse("This is **bold** text.")
        var runs: [InlineText.Run] = []
        runs.append(plain("This is "))
        runs.append(bold("bold"))
        runs.append(plain(" text."))

        #expect(document.chapters[0].blocks == [.paragraph(InlineText(runs: runs))])
    }

    @Test
    func italicCoversTheCorrectRun() {
        let document = parser.parse("This is *italic* text.")
        var runs: [InlineText.Run] = []
        runs.append(plain("This is "))
        runs.append(italic("italic"))
        runs.append(plain(" text."))

        #expect(document.chapters[0].blocks == [.paragraph(InlineText(runs: runs))])
    }

    @Test
    func underscoresAlsoMarkEmphasis() {
        let document = parser.parse("__bold__ and _italic_")
        var runs: [InlineText.Run] = []
        runs.append(bold("bold"))
        runs.append(plain(" and "))
        runs.append(italic("italic"))

        #expect(document.chapters[0].blocks == [.paragraph(InlineText(runs: runs))])
    }

    @Test
    func tripleMarkerMarksBoldAndItalic() {
        let document = parser.parse("***both***")
        var runs: [InlineText.Run] = []
        runs.append(boldItalic("both"))

        #expect(document.chapters[0].blocks == [.paragraph(InlineText(runs: runs))])
    }

    @Test
    func emphasisRunsInterleaveWithPlainText() {
        let document = parser.parse("a **b** c *d* e")
        var runs: [InlineText.Run] = []
        runs.append(plain("a "))
        runs.append(bold("b"))
        runs.append(plain(" c "))
        runs.append(italic("d"))
        runs.append(plain(" e"))

        #expect(document.chapters[0].blocks == [.paragraph(InlineText(runs: runs))])
    }

    @Test
    func intrawordUnderscoresAreNotEmphasis() {
        let document = parser.parse("snake_case_name")

        #expect(document.chapters[0].blocks == [.paragraph(InlineText("snake_case_name"))])
    }

    @Test
    func linkKeepsTextAndDropsTarget() {
        let document = parser.parse("See [the docs](https://example.com) now.")

        #expect(document.chapters[0].blocks == [.paragraph(InlineText("See the docs now."))])
    }

    @Test
    func imageIsNotRepresented() {
        let document = parser.parse("A![alt text](img.png)B")

        #expect(document.chapters[0].blocks == [.paragraph(InlineText("AB"))])
    }

    @Test
    func footnoteTargetIsNotRepresented() {
        let document = parser.parse("Text[^1] more")

        #expect(document.chapters[0].blocks == [.paragraph(InlineText("Text more"))])
    }

    @Test
    func quotesAndListItemsCarryInlineEmphasis() {
        let document = parser.parse("> **Bold** quote\n\n- *italic* item")
        var quoteRuns: [InlineText.Run] = []
        quoteRuns.append(bold("Bold"))
        quoteRuns.append(plain(" quote"))
        var itemRuns: [InlineText.Run] = []
        itemRuns.append(italic("italic"))
        itemRuns.append(plain(" item"))
        var expected: [Block] = []
        expected.append(.quote(InlineText(runs: quoteRuns)))
        expected.append(.listItem(InlineText(runs: itemRuns)))

        #expect(document.chapters[0].blocks == expected)
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

    private func boldItalic(_ string: String) -> InlineText.Run {
        InlineText.Run(text: string, isBold: true, isItalic: true)
    }
}
