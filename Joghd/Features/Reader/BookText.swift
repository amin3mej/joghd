import UIKit

enum BookText {
    private enum Metric {
        static let headingTitle: CGFloat = 30
        static let headingSection: CGFloat = 25
        static let headingSubsection: CGFloat = 21
        static let headingFallback: CGFloat = 19
        static let body: CGFloat = 18
        static let code: CGFloat = 15
        static let paragraphSpacing: CGFloat = 12
        static let headingSpacingBefore: CGFloat = 12
        static let headingSpacing: CGFloat = 8
        static let lineSpacing: CGFloat = 4
        static let quoteIndent: CGFloat = 16
        static let listIndent: CGFloat = 20
    }

    private enum HeadingLevel {
        static let title = 1
        static let section = 2
        static let subsection = 3
    }

    private static let dividerText = "— — —\n"

    static func attributedString(of document: BookDocument) -> NSAttributedString {
        let result = NSMutableAttributedString()
        for chapter in document.chapters {
            append(chapter, to: result)
        }
        return result
    }

    private static func append(_ chapter: Chapter, to result: NSMutableAttributedString) {
        appendChapterTitle(chapter, to: result)
        for block in chapter.blocks {
            append(block, to: result)
        }
    }

    private static func appendChapterTitle(
        _ chapter: Chapter, to result: NSMutableAttributedString
    ) {
        guard let title = chapter.title, !title.isEmpty else {
            return
        }
        guard !hasHeading(matching: title, in: chapter.blocks) else {
            return
        }
        appendHeading(text: InlineText(title), size: Metric.headingTitle, to: result)
    }

    private static func hasHeading(matching title: String, in blocks: [Block]) -> Bool {
        for block in blocks {
            guard case .heading(_, let text) = block else {
                continue
            }
            if text.plainText == title {
                return true
            }
        }
        return false
    }

    private static func append(_ block: Block, to result: NSMutableAttributedString) {
        switch block {
        case .heading(_, let text):
            appendHeading(text: text, size: headingSize(of: block), to: result)

        case .paragraph(let text):
            result.append(paragraph(text, size: Metric.body, style: bodyStyle()))

        case .quote(let text):
            let style = bodyStyle()
            style.headIndent = Metric.quoteIndent
            style.firstLineHeadIndent = Metric.quoteIndent
            result.append(paragraph(text, size: Metric.body, style: style) { _ in true })

        case .listItem(let text):
            let style = bodyStyle()
            style.headIndent = Metric.listIndent
            style.firstLineHeadIndent = Metric.listIndent
            let marker = baseAttributes(
                size: Metric.body, style: style, bold: false, italic: false
            )
            let item = NSMutableAttributedString(string: "• ", attributes: marker)
            item.append(paragraph(text, size: Metric.body, style: style))
            result.append(item)

        case .codeBlock(let code):
            let style = bodyStyle()
            result.append(
                paragraph(InlineText(code), size: Metric.code, style: style, monospaced: true)
            )

        case .divider:
            let style = bodyStyle()
            style.alignment = .center
            let attributes = baseAttributes(
                size: Metric.body, style: style, bold: false, italic: false
            )
            result.append(NSAttributedString(string: dividerText, attributes: attributes))
        }
    }

    private static func appendHeading(
        text: InlineText, size: CGFloat, to result: NSMutableAttributedString
    ) {
        let style = NSMutableParagraphStyle()
        style.paragraphSpacingBefore = Metric.headingSpacingBefore
        style.paragraphSpacing = Metric.headingSpacing
        result.append(paragraph(text, size: size, style: style, bold: true))
    }

    private static func headingSize(of block: Block) -> CGFloat {
        guard case .heading(let level, _) = block else {
            return Metric.headingFallback
        }
        switch level {
        case HeadingLevel.title:
            return Metric.headingTitle

        case HeadingLevel.section:
            return Metric.headingSection

        case HeadingLevel.subsection:
            return Metric.headingSubsection

        default:
            return Metric.headingFallback
        }
    }

    private static func bodyStyle() -> NSMutableParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.paragraphSpacing = Metric.paragraphSpacing
        style.lineSpacing = Metric.lineSpacing
        return style
    }

    private static func paragraph(
        _ text: InlineText,
        size: CGFloat,
        style: NSParagraphStyle,
        bold: Bool = false,
        monospaced: Bool = false,
        italic: (InlineText.Run) -> Bool = \.isItalic
    ) -> NSAttributedString {
        let result = NSMutableAttributedString()
        for run in text.runs {
            let attributes = baseAttributes(
                size: size,
                style: style,
                bold: bold || run.isBold,
                italic: italic(run),
                monospaced: monospaced
            )
            result.append(NSAttributedString(string: run.text, attributes: attributes))
        }
        result.append(
            NSAttributedString(
                string: "\n",
                attributes: baseAttributes(
                    size: size, style: style, bold: bold, italic: false, monospaced: monospaced
                )
            )
        )
        return result
    }

    private static func baseAttributes(
        size: CGFloat,
        style: NSParagraphStyle,
        bold: Bool,
        italic: Bool,
        monospaced: Bool = false
    ) -> [NSAttributedString.Key: Any] {
        let resolvedFont = font(size: size, bold: bold, italic: italic, monospaced: monospaced)
        return [.font: resolvedFont, .paragraphStyle: style]
    }

    private static func font(size: CGFloat, bold: Bool, italic: Bool, monospaced: Bool) -> UIFont {
        let base =
            monospaced
            ? UIFont.monospacedSystemFont(ofSize: size, weight: .regular)
            : UIFont.systemFont(ofSize: size)
        var traits: UIFontDescriptor.SymbolicTraits = []
        if bold { traits.insert(.traitBold) }
        if italic { traits.insert(.traitItalic) }
        guard !traits.isEmpty,
            let descriptor = base.fontDescriptor.withSymbolicTraits(traits)
        else {
            return base
        }
        return UIFont(descriptor: descriptor, size: size)
    }
}
