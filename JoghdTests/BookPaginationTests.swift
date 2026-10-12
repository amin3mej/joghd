import Foundation
import Testing
import UIKit

@testable import Joghd

@MainActor
struct BookPaginationTests {
    private let pageSize = CGSize(width: 200, height: 150)

    @Test
    func textLongerThanAPageSplitsAcrossPages() {
        let pages = BookPagination.pages(of: longText(), pageSize: pageSize)

        #expect(pages.count > 1)
    }

    @Test
    func everyCharacterSurvivesAcrossPages() {
        let text = longText()

        let pages = BookPagination.pages(of: text, pageSize: pageSize)

        #expect(pages.map(\.string).joined() == text.string)
    }

    @Test
    func textShorterThanAPageStaysOnOnePage() {
        let text = BookText.attributedString(
            of: BookDocument(
                title: nil,
                author: nil,
                chapters: [Chapter(title: nil, blocks: [.paragraph(InlineText("A short line."))])]
            )
        )

        let pages = BookPagination.pages(of: text, pageSize: CGSize(width: 300, height: 400))

        #expect(pages.count == 1)
    }

    @Test
    func pagingContinuesAcrossChapterBoundaries() {
        var chapters: [Chapter] = []
        chapters.append(Chapter(title: "One", blocks: [.paragraph(InlineText("alpha"))]))
        chapters.append(
            Chapter(
                title: "Two",
                blocks: [.paragraph(InlineText(String(repeating: "beta ", count: 200)))]
            )
        )
        let text = BookText.attributedString(
            of: BookDocument(title: nil, author: nil, chapters: chapters)
        )

        let pages = BookPagination.pages(of: text, pageSize: CGSize(width: 200, height: 500))

        #expect(pages.count > 1)
        #expect(pages.contains { $0.string.contains("alpha") && $0.string.contains("beta") })
        #expect(pages.map(\.string).joined() == text.string)
    }

    private func longText() -> NSAttributedString {
        let sentence = "The quick brown fox jumps over the lazy dog. "
        let paragraph = String(repeating: sentence, count: 200)
        return BookText.attributedString(
            of: BookDocument(
                title: nil,
                author: nil,
                chapters: [Chapter(title: nil, blocks: [.paragraph(InlineText(paragraph))])]
            )
        )
    }
}
