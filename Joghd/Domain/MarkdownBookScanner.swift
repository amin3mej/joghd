import Foundation

struct MarkdownBookScanner {
    private struct Fence {
        let character: Character
        let length: Int
    }

    private struct Heading {
        let level: Int
        let text: InlineText
    }

    private static let minimumFenceLength = 3
    private static let minimumDividerLength = 3
    private static let maximumHeadingLevel = 6

    private let lines: [String]
    private var index = 0
    private var chapters: [Chapter] = []
    private var chapterTitle: String?
    private var isChapterOpen = false
    private var sawTopLevelHeading = false
    private var blocks: [Block] = []
    private var paragraphLines: [String] = []

    init(lines: [String]) {
        self.lines = lines
    }

    mutating func scan() -> [Chapter] {
        while index < lines.count {
            scanLine(lines[index])
        }
        closeChapter()

        if !sawTopLevelHeading, chapters.isEmpty {
            chapters.append(Chapter(title: nil, blocks: []))
        }

        return chapters
    }

    private mutating func scanLine(_ line: String) {
        if let opener = fence(line) {
            scanCodeBlock(opener: opener)
        } else if let heading = heading(line) {
            scanHeading(heading)
        } else if isDivider(line) {
            flushParagraph()
            blocks.append(.divider)
            index += 1
        } else if isQuote(line) {
            scanQuote()
        } else if let item = listItem(line) {
            flushParagraph()
            appendText(item, make: Block.listItem)
            index += 1
        } else if isBlank(line) {
            flushParagraph()
            index += 1
        } else {
            paragraphLines.append(trimmed(line))
            index += 1
        }
    }

    private mutating func scanCodeBlock(opener: Fence) {
        flushParagraph()
        index += 1
        var code: [String] = []
        while index < lines.count, !closes(lines[index], opener: opener) {
            code.append(lines[index])
            index += 1
        }
        if index < lines.count {
            index += 1
        }
        blocks.append(.codeBlock(code.joined(separator: "\n")))
    }

    private mutating func scanHeading(_ heading: Heading) {
        if heading.level == 1 {
            closeChapter()
            sawTopLevelHeading = true
            let title = heading.text.plainText
            chapterTitle = title.isEmpty ? nil : title
            isChapterOpen = true
        } else {
            flushParagraph()
            blocks.append(.heading(level: heading.level, text: heading.text))
        }
        index += 1
    }

    private mutating func scanQuote() {
        flushParagraph()
        var quoteLines: [String] = []
        while index < lines.count, isQuote(lines[index]) {
            quoteLines.append(quoteContent(lines[index]))
            index += 1
        }
        appendText(quoteLines.joined(separator: " "), make: Block.quote)
    }

    private mutating func flushParagraph() {
        guard !paragraphLines.isEmpty else {
            return
        }
        let text = MarkdownInlineParser.parse(paragraphLines.joined(separator: " "))
        paragraphLines = []
        if !text.plainText.isEmpty {
            blocks.append(.paragraph(text))
        }
    }

    private mutating func closeChapter() {
        flushParagraph()
        guard isChapterOpen || !blocks.isEmpty else {
            return
        }
        chapters.append(Chapter(title: chapterTitle, blocks: blocks))
        chapterTitle = nil
        isChapterOpen = false
        blocks = []
    }

    private mutating func appendText(_ text: String, make: (InlineText) -> Block) {
        let inline = MarkdownInlineParser.parse(text)
        if !inline.plainText.isEmpty {
            blocks.append(make(inline))
        }
    }

    private func fence(_ line: String) -> Fence? {
        let trimmed = trimmed(line)
        guard let character = trimmed.first, character == "`" || character == "~" else {
            return nil
        }
        let length = trimmed.prefix { $0 == character }.count
        guard length >= Self.minimumFenceLength else {
            return nil
        }
        return Fence(character: character, length: length)
    }

    private func closes(_ line: String, opener: Fence) -> Bool {
        let trimmed = trimmed(line)
        let run = trimmed.prefix { $0 == opener.character }.count
        return run >= opener.length && run == trimmed.count
    }

    private func heading(_ line: String) -> Heading? {
        let trimmed = trimmed(line)
        let hashes = trimmed.prefix { $0 == "#" }
        let level = hashes.count
        guard (1...Self.maximumHeadingLevel).contains(level) else {
            return nil
        }

        let rest = trimmed.dropFirst(level)
        guard rest.isEmpty || rest.first == " " || rest.first == "\t" else {
            return nil
        }

        var text = rest.trimmingCharacters(in: .whitespaces)
        let trailingHashes = text.reversed().prefix { $0 == "#" }.count
        if trailingHashes > 0 {
            let beforeClosing = text[
                text.startIndex..<text.index(text.endIndex, offsetBy: -trailingHashes)]
            if !beforeClosing.isEmpty, beforeClosing.last?.isWhitespace == true {
                text = String(beforeClosing).trimmingCharacters(in: .whitespaces)
            }
        }
        return Heading(level: level, text: MarkdownInlineParser.parse(text))
    }

    private func isDivider(_ line: String) -> Bool {
        let trimmed = trimmed(line)
        guard let first = trimmed.first, "-*_".contains(first) else {
            return false
        }
        let compact = trimmed.filter { !$0.isWhitespace }
        guard compact.count >= Self.minimumDividerLength else {
            return false
        }
        return compact.allSatisfy { $0 == first }
    }

    private func isQuote(_ line: String) -> Bool {
        trimmed(line).hasPrefix(">")
    }

    private func quoteContent(_ line: String) -> String {
        var trimmed = trimmed(line)
        trimmed.removeFirst()
        if trimmed.hasPrefix(" ") {
            trimmed.removeFirst()
        }
        return trimmed
    }

    private func listItem(_ line: String) -> String? {
        let trimmed = trimmed(line)

        if let first = trimmed.first, "-*+".contains(first) {
            let rest = trimmed.dropFirst()
            if rest.hasPrefix(" ") {
                return rest.dropFirst().trimmingCharacters(in: .whitespaces)
            }
            return nil
        }

        var cursor = trimmed.startIndex
        var digits = ""
        while cursor < trimmed.endIndex, trimmed[cursor].isNumber {
            digits.append(trimmed[cursor])
            cursor = trimmed.index(after: cursor)
        }
        guard !digits.isEmpty, cursor < trimmed.endIndex,
            trimmed[cursor] == "." || trimmed[cursor] == ")"
        else {
            return nil
        }

        let afterMarker = trimmed.index(after: cursor)
        guard afterMarker < trimmed.endIndex, trimmed[afterMarker] == " " else {
            return nil
        }
        return trimmed[trimmed.index(after: afterMarker)...].trimmingCharacters(in: .whitespaces)
    }

    private func isBlank(_ line: String) -> Bool {
        trimmed(line).isEmpty
    }

    private func trimmed(_ line: String) -> String {
        line.trimmingCharacters(in: .whitespaces)
    }
}
