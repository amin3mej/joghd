import UIKit

@MainActor
final class BookPaginator {
    private let text: NSAttributedString
    private let pageSize: CGSize
    private let layoutManager: NSLayoutManager
    private let storage: NSTextStorage
    private var consumed = 0
    private var isExhausted = false

    var finished: Bool { isExhausted }

    init(text: NSAttributedString, pageSize: CGSize) {
        self.text = text
        self.pageSize = pageSize
        storage = NSTextStorage(attributedString: text)
        layoutManager = NSLayoutManager()
        storage.addLayoutManager(layoutManager)
    }

    @discardableResult
    func appendNextPage() -> BookPage? {
        guard !isExhausted else {
            return nil
        }

        if text.length == 0 || pageSize.width <= 0 || pageSize.height <= 0 {
            isExhausted = true
            return BookPage(text: text, range: NSRange(location: 0, length: text.length))
        }

        guard consumed < text.length else {
            isExhausted = true
            return nil
        }

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
            isExhausted = true
            return nil
        }

        let page = BookPage(
            text: text.attributedSubstring(from: characterRange),
            range: characterRange
        )
        consumed = NSMaxRange(characterRange)
        if consumed >= text.length {
            isExhausted = true
        }
        return page
    }
}
