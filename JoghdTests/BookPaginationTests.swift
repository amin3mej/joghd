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

        #expect(pages.map(\.text.string).joined() == text.string)
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
        #expect(
            pages.contains { $0.text.string.contains("alpha") && $0.text.string.contains("beta") }
        )
        #expect(pages.map(\.text.string).joined() == text.string)
    }

    @Test
    func findsThePageHoldingALocation() {
        let pages = samplePages()

        #expect(BookPagination.pageIndex(for: Location(index: 0), in: pages) == 0)
        #expect(BookPagination.pageIndex(for: Location(index: 2), in: pages) == 1)
    }

    @Test
    func clampsALocationPastTheEndToTheLastPage() {
        let pages = samplePages()

        #expect(BookPagination.pageIndex(for: Location(index: 100), in: pages) == 1)
    }

    @Test
    func anEmptyPaginationHasNoPageToFind() {
        #expect(BookPagination.pageIndex(for: Location(index: 3), in: []) == 0)
    }

    @Test
    func restoresToThePageWhereTheLocationWasReached() {
        let first = page(NSRange(location: 0, length: 300))
        let second = page(NSRange(location: 300, length: 300))

        #expect(BookPagination.pageIndex(for: Location(index: 2), in: [first, second]) == 1)
    }

    @Test
    func everyPageLocationRestoresToItsOwnPage() {
        let pages = BookPagination.pages(
            of: longText(), pageSize: CGSize(width: 400, height: 600)
        )

        for index in pages.indices {
            let location = Location(containing: pages[index].range.location)
            #expect(BookPagination.pageIndex(for: location, in: pages) == index)
        }
    }

    @Test
    func aLocationStillLandsOnItsTextAfterRepagination() {
        let text = longText()
        let wide = BookPagination.pages(of: text, pageSize: CGSize(width: 400, height: 600))
        let narrow = BookPagination.pages(of: text, pageSize: CGSize(width: 250, height: 350))
        let location = Location(containing: wide[4].range.location)
        let locationRange = NSRange(location: location.characterOffset, length: 128)
        let index = BookPagination.pageIndex(for: location, in: narrow)

        #expect(NSIntersectionRange(narrow[index].range, locationRange).length > 0)
    }

    private func samplePages() -> [BookPage] {
        let first = page(NSRange(location: 0, length: 200))
        let second = page(NSRange(location: 200, length: 300))
        return [first, second]
    }

    private func page(_ range: NSRange) -> BookPage {
        BookPage(text: NSAttributedString(string: ""), range: range)
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
