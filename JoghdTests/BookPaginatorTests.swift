import Foundation
import Testing
import UIKit

@testable import Joghd

@MainActor
struct BookPaginatorTests {
    private let pageSize = CGSize(width: 354, height: 700)

    @Test
    func producesTheFirstPageWithoutPaginatingTheWholeBook() throws {
        let text = largeBookText()
        #expect(text.length >= 1_400_000)

        let paginator = BookPaginator(text: text, pageSize: pageSize)
        let first = try #require(paginator.appendNextPage())

        #expect(!paginator.finished)
        #expect(first.range.location == 0)
        #expect(NSMaxRange(first.range) < text.length)
    }

    @Test
    func firstPageOfALargeBookCompletesWithinABoundedTime() {
        let text = largeBookText()

        let elapsed = ContinuousClock().measure {
            let paginator = BookPaginator(text: text, pageSize: pageSize)
            _ = paginator.appendNextPage()
        }

        #expect(elapsed < .seconds(2))
    }

    @Test
    func incrementalPaginationPreservesEveryCharacter() {
        let text = BookText.attributedString(of: manyChapterDocument(chapters: 4))

        let paginator = BookPaginator(text: text, pageSize: CGSize(width: 200, height: 150))
        var pages: [BookPage] = []
        while let page = paginator.appendNextPage() {
            pages.append(page)
        }

        #expect(paginator.finished)
        #expect(pages.map(\.text.string).joined() == text.string)
    }

    @Test
    func emptyTextYieldsASingleEmptyPage() {
        let text = NSAttributedString(string: "")

        let paginator = BookPaginator(text: text, pageSize: pageSize)
        let page = paginator.appendNextPage()

        #expect(page?.range == NSRange(location: 0, length: 0))
        #expect(paginator.finished)
        #expect(paginator.appendNextPage() == nil)
    }

    @Test
    func incrementalPaginationReachesAndIdentifiesADeepLocation() {
        let text = BookText.attributedString(of: manyChapterDocument(chapters: 40))
        let target = Location(characterOffset: text.length / 2)

        let paginator = BookPaginator(text: text, pageSize: CGSize(width: 250, height: 350))
        var pages: [BookPage] = []
        while let page = paginator.appendNextPage() {
            pages.append(page)
            if page.contains(characterOffset: target.characterOffset) {
                break
            }
        }

        let index = BookPagination.pageIndex(for: target, in: pages)
        #expect(pages.indices.contains(index))
        let locationRange = NSRange(location: target.characterOffset, length: 128)
        #expect(NSIntersectionRange(pages[index].range, locationRange).length > 0)
    }

    private func manyChapterDocument(chapters: Int) -> BookDocument {
        var result: [Chapter] = []
        for chapter in 1...chapters {
            var blocks: [Block] = []
            blocks.append(.heading(level: 1, text: InlineText("Chapter \(chapter)")))
            for paragraph in 1...20 {
                blocks.append(
                    .paragraph(
                        InlineText(
                            "Chapter \(chapter), paragraph \(paragraph). "
                                + "The quick brown fox jumps over the lazy dog."
                        )
                    )
                )
            }
            result.append(Chapter(title: "Chapter \(chapter)", blocks: blocks))
        }
        return BookDocument(title: "Many Chapters", author: nil, chapters: result)
    }

    private func largeBookText() -> NSAttributedString {
        let sentence =
            "The quick brown fox jumps over the lazy dog while the reader follows each page "
            + "of this long synthetic book to exercise native pagination across many chapters "
            + "of deterministic prose that stands in for a real imported title without carrying "
            + "any copyrighted content. "
        var chapters: [Chapter] = []
        for chapter in 1...83 {
            var blocks: [Block] = []
            blocks.append(.heading(level: 1, text: InlineText("Chapter \(chapter)")))
            for paragraph in 1...70 {
                blocks.append(
                    .paragraph(
                        InlineText("Chapter \(chapter), paragraph \(paragraph). " + sentence)
                    )
                )
            }
            chapters.append(Chapter(title: "Chapter \(chapter)", blocks: blocks))
        }
        return BookText.attributedString(
            of: BookDocument(title: "Synthetic", author: "Fixture", chapters: chapters)
        )
    }
}
