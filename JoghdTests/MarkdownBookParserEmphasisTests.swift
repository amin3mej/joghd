import Foundation
import Testing

@testable import Joghd

struct MarkdownBookParserEmphasisTests {
    private let parser = MarkdownBookParser()

    @Test
    func boldCoversTheCorrectRun() {
        let document = parser.parse("This is **bold** text.")

        let expected = blocks(
            paragraph(
                plain("This is "),
                bold("bold"),
                plain(" text.")
            )
        )
        #expect(document.chapters[0].blocks == expected)
    }

    @Test
    func italicCoversTheCorrectRun() {
        let document = parser.parse("This is *italic* text.")

        let expected = blocks(
            paragraph(
                plain("This is "),
                italic("italic"),
                plain(" text.")
            )
        )
        #expect(document.chapters[0].blocks == expected)
    }

    @Test
    func underscoresAlsoMarkEmphasis() {
        let document = parser.parse("__bold__ and _italic_")

        let expected = blocks(
            paragraph(
                bold("bold"),
                plain(" and "),
                italic("italic")
            )
        )
        #expect(document.chapters[0].blocks == expected)
    }

    @Test
    func tripleMarkerMarksBoldAndItalic() {
        let document = parser.parse("***both***")

        #expect(document.chapters[0].blocks == blocks(paragraph(boldItalic("both"))))
    }

    @Test
    func emphasisRunsInterleaveWithPlainText() {
        let document = parser.parse("a **b** c *d* e")

        let expected = blocks(
            paragraph(
                plain("a "),
                bold("b"),
                plain(" c "),
                italic("d"),
                plain(" e")
            )
        )
        #expect(document.chapters[0].blocks == expected)
    }

    @Test
    func intrawordUnderscoresAreNotEmphasis() {
        let document = parser.parse("snake_case_name")

        #expect(document.chapters[0].blocks == blocks(.paragraph(InlineText("snake_case_name"))))
    }

    @Test
    func linkKeepsTextAndDropsTarget() {
        let document = parser.parse("See [the docs](https://example.com) now.")

        #expect(document.chapters[0].blocks == blocks(.paragraph(InlineText("See the docs now."))))
    }

    @Test
    func imageIsNotRepresented() {
        let document = parser.parse("A![alt text](img.png)B")

        #expect(document.chapters[0].blocks == blocks(.paragraph(InlineText("AB"))))
    }

    @Test
    func footnoteTargetIsNotRepresented() {
        let document = parser.parse("Text[^1] more")

        #expect(document.chapters[0].blocks == blocks(.paragraph(InlineText("Text more"))))
    }

    private func blocks(_ items: Block...) -> [Block] {
        items
    }

    private func paragraph(_ runs: InlineText.Run...) -> Block {
        .paragraph(InlineText(runs: runs))
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
