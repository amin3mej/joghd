import Foundation
import Testing
import UIKit

@testable import Joghd

@MainActor
struct BookTextTests {
    @Test
    func headingRendersLargerThanBodyText() throws {
        let heading = Block.heading(level: 1, text: InlineText("Chapter One"))
        let body = Block.paragraph(InlineText("Body text"))
        let text = BookText.attributedString(of: document(blocks: [heading, body]))

        let headingFont = try font(in: text, for: "Chapter One")
        let bodyFont = try font(in: text, for: "Body text")

        #expect(headingFont.pointSize > bodyFont.pointSize)
    }

    @Test
    func headingRendersBold() throws {
        let heading = Block.heading(level: 2, text: InlineText("Chapter One"))
        let text = BookText.attributedString(of: document(blocks: [heading]))

        let headingFont = try font(in: text, for: "Chapter One")

        #expect(headingFont.fontDescriptor.symbolicTraits.contains(.traitBold))
    }

    @Test
    func boldAndItalicRunsKeepTheirTraits() throws {
        var runs: [InlineText.Run] = []
        runs.append(.init(text: "plain "))
        runs.append(.init(text: "bold", isBold: true))
        runs.append(.init(text: " "))
        runs.append(.init(text: "italic", isItalic: true))
        let paragraph = Block.paragraph(InlineText(runs: runs))
        let text = BookText.attributedString(of: document(blocks: [paragraph]))

        let plain = try font(in: text, for: "plain")
        let bold = try font(in: text, for: "bold")
        let italic = try font(in: text, for: "italic")

        #expect(!plain.fontDescriptor.symbolicTraits.contains(.traitBold))
        #expect(bold.fontDescriptor.symbolicTraits.contains(.traitBold))
        #expect(italic.fontDescriptor.symbolicTraits.contains(.traitItalic))
    }

    @Test
    func chapterTitleBecomesAHeadingWithoutDuplicatingTheFirstHeadingBlock() {
        var blocks: [Block] = []
        blocks.append(.heading(level: 1, text: InlineText("Chapter One")))
        blocks.append(.paragraph(InlineText("Body")))
        let chapter = Chapter(title: "Chapter One", blocks: blocks)
        let text = BookText.attributedString(
            of: BookDocument(title: nil, author: nil, chapters: [chapter])
        )

        let occurrences = text.string.components(separatedBy: "Chapter One").count - 1

        #expect(occurrences == 1)
    }

    private func document(blocks: [Block]) -> BookDocument {
        let chapter = Chapter(title: nil, blocks: blocks)
        return BookDocument(title: nil, author: nil, chapters: [chapter])
    }

    private func font(in text: NSAttributedString, for substring: String) throws -> UIFont {
        let range = try #require(text.string.range(of: substring))
        let location = NSRange(range, in: text.string).location
        return try #require(
            text.attribute(.font, at: location, effectiveRange: nil) as? UIFont
        )
    }
}
