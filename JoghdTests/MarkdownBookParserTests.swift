import Foundation
import Testing

@testable import Joghd

struct MarkdownBookParserTests {
    private let parser = MarkdownBookParser()

    @Test
    func paragraphBecomesASingleChapter() {
        let document = parser.parse("Hello world.")

        #expect(document.chapters.count == 1)
        #expect(document.chapters[0].title == nil)
        #expect(document.chapters[0].blocks == blocks(.paragraph(InlineText("Hello world."))))
    }

    @Test
    func blankLineSeparatesParagraphs() {
        let document = parser.parse("First paragraph.\n\nSecond paragraph.")

        let expected = blocks(
            .paragraph(InlineText("First paragraph.")),
            .paragraph(InlineText("Second paragraph."))
        )
        #expect(document.chapters[0].blocks == expected)
    }

    @Test
    func topLevelHeadingStartsAChapterAndNamesIt() {
        let document = parser.parse("# Chapter One\n\nSome text.")

        #expect(document.chapters.count == 1)
        #expect(document.chapters[0].title == "Chapter One")
        #expect(document.chapters[0].blocks == blocks(.paragraph(InlineText("Some text."))))
    }

    @Test
    func oneTopLevelHeadingPerChapterYieldsOneChapterPerHeading() {
        let document = parser.parse(
            """
            # One

            First.

            # Two

            Second.
            """
        )

        #expect(document.chapters.count == 2)
        #expect(document.chapters.map(\.title) == ["One", "Two"])
        #expect(document.chapters[0].blocks == blocks(.paragraph(InlineText("First."))))
        #expect(document.chapters[1].blocks == blocks(.paragraph(InlineText("Second."))))
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
        let document = parser.parse(
            """
            # Chapter

            ## Section

            Body.
            """
        )

        let expected = blocks(
            .heading(level: 2, text: InlineText("Section")),
            .paragraph(InlineText("Body."))
        )
        #expect(document.chapters.count == 1)
        #expect(document.chapters[0].title == "Chapter")
        #expect(document.chapters[0].blocks == expected)
    }

    @Test
    func contentBeforeTheFirstHeadingBecomesAnUntitledChapter() {
        let document = parser.parse(
            """
            Preamble.

            # Chapter

            Body.
            """
        )

        #expect(document.chapters.count == 2)
        #expect(document.chapters[0].title == nil)
        #expect(document.chapters[0].blocks == blocks(.paragraph(InlineText("Preamble."))))
        #expect(document.chapters[1].title == "Chapter")
    }

    @Test
    func parsesMarkdownFromAFile() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString).md")
        try "# Chapter\n\nBody.".write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }

        let document = try parser.parse(contentsOf: url)

        #expect(document.chapters.map(\.title) == ["Chapter"])
        #expect(document.chapters[0].blocks == blocks(.paragraph(InlineText("Body."))))
    }

    @Test
    func unreadableFileThrowsInsteadOfReturningAPartialDocument() {
        let missing = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString).md")

        #expect(throws: (any Error).self) {
            try parser.parse(contentsOf: missing)
        }
    }

    private func blocks(_ items: Block...) -> [Block] {
        items
    }
}
