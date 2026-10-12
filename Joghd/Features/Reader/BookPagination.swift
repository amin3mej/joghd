import UIKit

@MainActor
enum BookPagination {
    static func pages(of text: NSAttributedString, pageSize: CGSize) -> [NSAttributedString] {
        guard text.length > 0 else {
            return [text]
        }
        guard pageSize.width > 0, pageSize.height > 0 else {
            return [text]
        }

        let storage = NSTextStorage(attributedString: text)
        let layoutManager = NSLayoutManager()
        storage.addLayoutManager(layoutManager)

        var pages: [NSAttributedString] = []
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
            pages.append(text.attributedSubstring(from: characterRange))
            consumed = NSMaxRange(characterRange)
        }
        return pages
    }
}
