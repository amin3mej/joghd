import Foundation

enum MarkdownBlockScanner {
    typealias Scan = (block: Block?, next: Int)

    private static let headingLevels = 1...6
    private static let fenceLength = 3
    private static let dividerLength = 3

    static func scan(_ lines: [String]) -> [Block] {
        var blocks: [Block] = []
        var index = 0
        while index < lines.count {
            let (block, next) = self.block(in: lines, at: index)
            if let block {
                blocks.append(block)
            }
            index = next
        }
        return blocks
    }

    private static func block(in lines: [String], at index: Int) -> Scan {
        let line = lines[index]
        if codeFence(line) != nil {
            return codeBlock(in: lines, at: index)
        }
        if let heading = atxHeading(line) {
            return (.heading(level: heading.level, text: heading.text), index + 1)
        }
        if isDivider(line) {
            return (.divider, index + 1)
        }
        if isQuote(line) {
            return quoteBlock(in: lines, at: index)
        }
        if let item = listItem(line) {
            return listItemBlock(item, at: index)
        }
        if isBlank(line) {
            return (nil, index + 1)
        }
        return paragraph(in: lines, at: index)
    }

    private static func codeBlock(in lines: [String], at index: Int) -> Scan {
        let opener = lines[index].trimmingCharacters(in: .whitespaces)
        guard let marker = opener.first else {
            return (nil, index + 1)
        }
        let openLength = opener.prefix { $0 == marker }.count
        var end = index + 1
        var code: [String] = []
        while end < lines.count, !isClosingFence(lines[end], marker: marker, length: openLength) {
            code.append(lines[end])
            end += 1
        }
        if end < lines.count {
            end += 1
        }
        return (.codeBlock(code.joined(separator: "\n")), end)
    }

    private static func isClosingFence(_ line: String, marker: Character, length: Int) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let run = trimmed.prefix { $0 == marker }.count
        guard run >= length else {
            return false
        }
        return trimmed.dropFirst(run).allSatisfy(\.isWhitespace)
    }

    private static func quoteBlock(in lines: [String], at index: Int) -> Scan {
        var end = index
        var quoteLines: [String] = []
        while end < lines.count, isQuote(lines[end]) {
            quoteLines.append(quoteContent(lines[end]))
            end += 1
        }
        let text = MarkdownInlineText.parse(quoteLines.joined(separator: " "))
        return (text.plainText.isEmpty ? nil : .quote(text), end)
    }

    private static func listItemBlock(_ item: String, at index: Int) -> Scan {
        let text = MarkdownInlineText.parse(item)
        return (text.plainText.isEmpty ? nil : .listItem(text), index + 1)
    }

    private static func paragraph(in lines: [String], at index: Int) -> Scan {
        var end = index
        var paragraphLines: [String] = []
        while end < lines.count, isParagraphLine(lines[end]) {
            paragraphLines.append(lines[end].trimmingCharacters(in: .whitespaces))
            end += 1
        }
        let text = MarkdownInlineText.parse(paragraphLines.joined(separator: " "))
        return (text.plainText.isEmpty ? nil : .paragraph(text), end)
    }

    private static func isParagraphLine(_ line: String) -> Bool {
        if isBlank(line) {
            return false
        }
        if codeFence(line) != nil {
            return false
        }
        if atxHeading(line) != nil {
            return false
        }
        if isDivider(line) {
            return false
        }
        if isQuote(line) {
            return false
        }
        if listItem(line) != nil {
            return false
        }
        return true
    }

    private static func atxHeading(_ line: String) -> (level: Int, text: InlineText)? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let hashes = trimmed.prefix { $0 == "#" }
        let level = hashes.count
        guard headingLevels.contains(level) else {
            return nil
        }
        let rest = trimmed.dropFirst(level)
        guard rest.isEmpty || rest.first == " " || rest.first == "\t" else {
            return nil
        }
        let text = droppingClosingHashes(rest.trimmingCharacters(in: .whitespaces))
        return (level, MarkdownInlineText.parse(text))
    }

    private static func droppingClosingHashes(_ text: String) -> String {
        let trailingHashes = text.reversed().prefix { $0 == "#" }.count
        guard trailingHashes > 0 else {
            return text
        }
        let beforeClosing = text[
            text.startIndex..<text.index(text.endIndex, offsetBy: -trailingHashes)
        ]
        guard !beforeClosing.isEmpty, beforeClosing.last?.isWhitespace == true else {
            return text
        }
        return String(beforeClosing).trimmingCharacters(in: .whitespaces)
    }

    private static func codeFence(_ line: String) -> Character? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= fenceLength else {
            return nil
        }
        let character = trimmed[trimmed.startIndex]
        guard character == "`" || character == "~" else {
            return nil
        }
        guard trimmed.prefix(fenceLength).allSatisfy({ $0 == character }) else {
            return nil
        }
        return character
    }

    private static func isDivider(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard let first = trimmed.first, "-*_".contains(first) else {
            return false
        }
        let compact = trimmed.filter { character in !character.isWhitespace }
        guard compact.count >= dividerLength else {
            return false
        }
        return compact.allSatisfy { character in character == first }
    }

    private static func isQuote(_ line: String) -> Bool {
        line.trimmingCharacters(in: .whitespaces).hasPrefix(">")
    }

    private static func quoteContent(_ line: String) -> String {
        var trimmed = line.trimmingCharacters(in: .whitespaces)
        trimmed.removeFirst()
        if trimmed.hasPrefix(" ") {
            trimmed.removeFirst()
        }
        return trimmed
    }

    private static func listItem(_ line: String) -> String? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if let marker = trimmed.first, "-*+".contains(marker) {
            let rest = trimmed.dropFirst()
            guard rest.hasPrefix(" ") else {
                return nil
            }
            return rest.dropFirst().trimmingCharacters(in: .whitespaces)
        }
        return orderedListItem(trimmed)
    }

    private static func orderedListItem(_ line: String) -> String? {
        var index = line.startIndex
        var digits = ""
        while index < line.endIndex, line[index].isNumber {
            digits.append(line[index])
            index = line.index(after: index)
        }
        guard !digits.isEmpty, index < line.endIndex,
            line[index] == "." || line[index] == ")"
        else {
            return nil
        }
        let afterMarker = line.index(after: index)
        guard afterMarker < line.endIndex, line[afterMarker] == " " else {
            return nil
        }
        return line[line.index(after: afterMarker)...].trimmingCharacters(in: .whitespaces)
    }

    private static func isBlank(_ line: String) -> Bool {
        line.trimmingCharacters(in: .whitespaces).isEmpty
    }
}
