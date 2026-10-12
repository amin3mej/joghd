import UIKit

@MainActor
enum BookPagination {
    static func pages(of text: NSAttributedString, pageSize: CGSize) -> [BookPage] {
        guard text.length > 0 else {
            return [BookPage(text: text, range: NSRange(location: 0, length: 0))]
        }
        guard pageSize.width > 0, pageSize.height > 0 else {
            return [BookPage(text: text, range: NSRange(location: 0, length: text.length))]
        }

        let storage = NSTextStorage(attributedString: text)
        let layoutManager = NSLayoutManager()
        storage.addLayoutManager(layoutManager)

        var pages: [BookPage] = []
        var consumed = 0
        while consumed < text.length {
            let container = NSTextContainer(size: pageSize)
            container.lineFragmentPadding = 0
            container.maximumNumberOfLines = 0
            layoutManager.addTextContainer(container)
            layoutManager.ensureLayout(for: container)

            let glyphRange = layoutManager.glyphRange(for: container)
            let characterRange = layoutManager.characterRange(
                forGlyphRange: glyphRange, actualGlyphRange: nil
            )
            guard characterRange.length > 0, NSMaxRange(characterRange) > consumed else {
                break
            }
            pages.append(
                BookPage(
                    text: text.attributedSubstring(from: characterRange),
                    range: characterRange
                )
            )
            consumed = NSMaxRange(characterRange)
        }
        return pages
    }

    static func pageIndex(for location: Location, in pages: [BookPage]) -> Int {
        guard let first = pages.first else {
            return 0
        }
        let offset = location.characterOffset
        if let index = pages.firstIndex(where: { page in
            page.range.location <= offset && offset < NSMaxRange(page.range)
        }) {
            return index
        }
        return offset < first.range.location ? 0 : pages.count - 1
    }
}
