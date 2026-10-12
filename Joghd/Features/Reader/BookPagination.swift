import UIKit

@MainActor
enum BookPagination {
    static func pages(of text: NSAttributedString, pageSize: CGSize) -> [BookPage] {
        let paginator = BookPaginator(text: text, pageSize: pageSize)
        var pages: [BookPage] = []
        while let page = paginator.appendNextPage() {
            pages.append(page)
        }
        return pages
    }

    static func pageIndex(for location: Location, in pages: [BookPage]) -> Int {
        guard let first = pages.first else {
            return 0
        }
        let offset = location.characterOffset
        if let index = pages.firstIndex(where: { $0.contains(characterOffset: offset) }) {
            return index
        }
        return offset < first.range.location ? 0 : pages.count - 1
    }
}
