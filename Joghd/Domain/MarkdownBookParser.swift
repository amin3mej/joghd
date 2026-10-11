import Foundation

/// Turns a Markdown file into a `BookDocument`. Top-level (`#`) headings open
/// chapters; every other block stays within its chapter. See ADR-0002: this
/// lives in Shared core so Import can validate a file and Reader can render it
/// from the same document.
struct MarkdownBookParser {
    func parse(_ markdown: String) -> BookDocument {
        var lines = Self.lines(of: markdown)
        let frontMatter = Self.takeFrontMatter(&lines)

        var chapters: [Chapter] = []
        var chapterTitle: String?
        var hasChapter = false
        var blocks: [Block] = []
        var paragraphLines: [String] = []

        func flushParagraph() {
            guard !paragraphLines.isEmpty else { return }
            let text = Self.inlineText(paragraphLines.joined(separator: " "))
            paragraphLines = []
            if !text.plainText.isEmpty {
                blocks.append(.paragraph(text))
            }
        }

        func closeChapter() {
            flushParagraph()
            guard hasChapter || !blocks.isEmpty else { return }
            chapters.append(Chapter(title: chapterTitle, blocks: blocks))
            chapterTitle = nil
            hasChapter = false
            blocks = []
        }

        var index = 0
        while index < lines.count {
            let line = lines[index]

            if Self.codeFence(line) != nil {
                flushParagraph()
                index += 1
                var code: [String] = []
                while index < lines.count, Self.codeFence(lines[index]) == nil {
                    code.append(lines[index])
                    index += 1
                }
                if index < lines.count { index += 1 }
                blocks.append(.codeBlock(code.joined(separator: "\n")))
            } else if let heading = Self.atxHeading(line) {
                if heading.level == 1 {
                    closeChapter()
                    chapterTitle = heading.text.plainText
                    hasChapter = true
                } else {
                    flushParagraph()
                    blocks.append(.heading(level: heading.level, text: heading.text))
                }
                index += 1
            } else if Self.isDivider(line) {
                flushParagraph()
                blocks.append(.divider)
                index += 1
            } else if Self.isQuote(line) {
                flushParagraph()
                var quoteLines: [String] = []
                while index < lines.count, Self.isQuote(lines[index]) {
                    quoteLines.append(Self.quoteContent(lines[index]))
                    index += 1
                }
                blocks.append(.quote(Self.inlineText(quoteLines.joined(separator: " "))))
            } else if let item = Self.listItem(line) {
                flushParagraph()
                blocks.append(.listItem(Self.inlineText(item)))
                index += 1
            } else if line.trimmingCharacters(in: .whitespaces).isEmpty {
                flushParagraph()
                index += 1
            } else {
                paragraphLines.append(line.trimmingCharacters(in: .whitespaces))
                index += 1
            }
        }
        closeChapter()

        return BookDocument(
            title: frontMatter.title,
            author: frontMatter.author,
            chapters: chapters
        )
    }

    /// Reads a Markdown file into a book document. An unreadable file throws
    /// rather than yielding a partial document.
    func parse(contentsOf url: URL) throws -> BookDocument {
        let data = try Data(contentsOf: url)
        guard let markdown = String(data: data, encoding: .utf8) else {
            throw BookParsingError.notUTF8(url)
        }
        return parse(markdown)
    }

    // MARK: - Block scanning

    private static func lines(of markdown: String) -> [String] {
        markdown
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .components(separatedBy: "\n")
    }

    private static func atxHeading(_ line: String) -> (level: Int, text: InlineText)? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let hashes = trimmed.prefix { $0 == "#" }
        let level = hashes.count
        guard (1...6).contains(level) else { return nil }

        let rest = trimmed.dropFirst(level)
        guard rest.isEmpty || rest.first == " " || rest.first == "\t" else { return nil }

        var text = rest.trimmingCharacters(in: .whitespaces)
        while text.hasSuffix("#") {
            text.removeLast()
        }
        text = text.trimmingCharacters(in: .whitespaces)
        return (level, inlineText(text))
    }

    /// The fence character of a fenced code block line, or `nil`.
    private static func codeFence(_ line: String) -> Character? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 3 else { return nil }
        let character = trimmed[trimmed.startIndex]
        guard character == "`" || character == "~" else { return nil }
        guard trimmed.prefix(3).allSatisfy({ $0 == character }) else { return nil }
        return character
    }

    private static func isDivider(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard let first = trimmed.first, "-*_".contains(first) else { return false }
        let compact = trimmed.filter { !$0.isWhitespace }
        guard compact.count >= 3 else { return false }
        return compact.allSatisfy { $0 == first }
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

        if let first = trimmed.first, "-*+".contains(first) {
            let rest = trimmed.dropFirst()
            if rest.hasPrefix(" ") {
                return rest.dropFirst().trimmingCharacters(in: .whitespaces)
            }
            return nil
        }

        var index = trimmed.startIndex
        var digits = ""
        while index < trimmed.endIndex, trimmed[index].isNumber {
            digits.append(trimmed[index])
            index = trimmed.index(after: index)
        }
        guard !digits.isEmpty, index < trimmed.endIndex,
              trimmed[index] == "." || trimmed[index] == ")"
        else { return nil }

        let afterMarker = trimmed.index(after: index)
        guard afterMarker < trimmed.endIndex, trimmed[afterMarker] == " " else { return nil }
        return trimmed[trimmed.index(after: afterMarker)...]
            .trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Front matter

    private struct FrontMatter {
        var title: String?
        var author: String?
    }

    /// Consumes a leading `---` YAML front-matter block, if present, returning
    /// its title and author and leaving the remaining lines in `lines`.
    private static func takeFrontMatter(_ lines: inout [String]) -> FrontMatter {
        guard lines.first?.trimmingCharacters(in: .whitespaces) == "---" else {
            return FrontMatter()
        }
        guard let closing = lines.dropFirst().firstIndex(where: {
            let trimmed = $0.trimmingCharacters(in: .whitespaces)
            return trimmed == "---" || trimmed == "..."
        }) else {
            return FrontMatter()
        }

        var frontMatter = FrontMatter()
        for line in lines[1..<closing] {
            guard let colon = line.firstIndex(of: ":") else { continue }
            let key = line[..<colon].trimmingCharacters(in: .whitespaces).lowercased()
            let value = unquoted(line[line.index(after: colon)...]
                .trimmingCharacters(in: .whitespaces))
            switch key {
            case "title": frontMatter.title = value.isEmpty ? nil : value
            case "author": frontMatter.author = value.isEmpty ? nil : value
            default: break
            }
        }

        lines = Array(lines[(closing + 1)...])
        return frontMatter
    }

    private static func unquoted(_ value: String) -> String {
        guard value.count >= 2,
              let first = value.first, first == "\"" || first == "'",
              value.last == first
        else { return value }
        return String(value.dropFirst().dropLast())
    }

    // MARK: - Inline scanning

    private struct Emphasis {
        let isBold: Bool
        let isItalic: Bool
        let content: ArraySlice<Character>
        let end: Int
    }

    private static func inlineText(_ string: String) -> InlineText {
        InlineText(runs: coalesce(parseRuns(Array(string))))
    }

    /// Merges neighbouring runs that carry the same emphasis, so that text
    /// split only by dropped markup (links, images) reads as one run.
    private static func coalesce(_ runs: [InlineText.Run]) -> [InlineText.Run] {
        var result: [InlineText.Run] = []
        for run in runs where !run.text.isEmpty {
            if var last = result.last, last.isBold == run.isBold, last.isItalic == run.isItalic {
                last.text += run.text
                result[result.count - 1] = last
            } else {
                result.append(run)
            }
        }
        return result
    }

    private static func parseRuns(
        _ chars: [Character],
        isBold: Bool = false,
        isItalic: Bool = false
    ) -> [InlineText.Run] {
        var runs: [InlineText.Run] = []
        var buffer = ""
        let bold = isBold
        let italic = isItalic
        var i = 0

        func flush() {
            guard !buffer.isEmpty else { return }
            runs.append(InlineText.Run(text: buffer, isBold: bold, isItalic: italic))
            buffer = ""
        }

        while i < chars.count {
            let character = chars[i]

            // Image: ![alt](target) — not represented.
            if character == "!", i + 1 < chars.count, chars[i + 1] == "[",
               let link = matchLink(chars, openingBracket: i + 1) {
                i = link.end
                continue
            }

            if character == "[" {
                // Footnote target: [^n] — not represented.
                if i + 1 < chars.count, chars[i + 1] == "^",
                   let end = matchClosing(chars, from: i, open: "[", close: "]") {
                    i = end
                    continue
                }
                // Link: keep the label, drop the target.
                if let link = matchLink(chars, openingBracket: i) {
                    flush()
                    runs.append(contentsOf: parseRuns(
                        Array(link.label),
                        isBold: bold,
                        isItalic: italic
                    ))
                    i = link.end
                    continue
                }
            }

            if character == "*" || character == "_",
               let emphasis = matchEmphasis(chars, at: i) {
                flush()
                runs.append(contentsOf: parseRuns(
                    Array(emphasis.content),
                    isBold: bold || emphasis.isBold,
                    isItalic: italic || emphasis.isItalic
                ))
                i = emphasis.end
                continue
            }

            buffer.append(character)
            i += 1
        }
        flush()
        return runs
    }

    /// Matches `[label](target)` starting at the opening bracket, returning the
    /// label and the index just past the closing parenthesis.
    private static func matchLink(
        _ chars: [Character],
        openingBracket: Int
    ) -> (label: String, end: Int)? {
        guard let labelEnd = matchClosing(chars, from: openingBracket, open: "[", close: "]"),
              labelEnd < chars.count, chars[labelEnd] == "(",
              let targetEnd = matchClosing(chars, from: labelEnd, open: "(", close: ")")
        else { return nil }

        let label = String(chars[(openingBracket + 1)..<(labelEnd - 1)])
        return (label, targetEnd)
    }

    /// Finds the index just past the `close` that matches the `open` at `start`.
    private static func matchClosing(
        _ chars: [Character],
        from start: Int,
        open: Character,
        close: Character
    ) -> Int? {
        var depth = 0
        var i = start
        while i < chars.count {
            if chars[i] == open {
                depth += 1
            } else if chars[i] == close {
                depth -= 1
                if depth == 0 { return i + 1 }
            }
            i += 1
        }
        return nil
    }

    /// Recognizes a balanced emphasis marker at `index`, if one starts there.
    private static func matchEmphasis(_ chars: [Character], at index: Int) -> Emphasis? {
        let marker = chars[index]
        var run = 0
        while index + run < chars.count, chars[index + run] == marker, run < 3 {
            run += 1
        }
        let length = min(run, 3)

        // An opening marker must be followed by non-whitespace.
        let afterOpening = index + length
        guard afterOpening < chars.count, !chars[afterOpening].isWhitespace else { return nil }

        // Underscores do not mark emphasis inside a word.
        if marker == "_", index > 0, chars[index - 1].isLetter || chars[index - 1].isNumber {
            return nil
        }

        var closer = afterOpening
        while closer < chars.count {
            guard chars[closer] == marker else {
                closer += 1
                continue
            }
            var closerRun = 0
            while closer + closerRun < chars.count, chars[closer + closerRun] == marker {
                closerRun += 1
            }
            let precededByNonSpace = closer > 0 && !chars[closer - 1].isWhitespace
            let wordBoundary = marker != "_"
                || closer + closerRun >= chars.count
                || !(chars[closer + closerRun].isLetter || chars[closer + closerRun].isNumber)
            if closerRun >= length, precededByNonSpace, wordBoundary {
                return Emphasis(
                    isBold: length >= 2,
                    isItalic: length == 1 || length == 3,
                    content: chars[afterOpening..<closer],
                    end: closer + length
                )
            }
            closer += closerRun
        }
        return nil
    }
}

/// Why a file could not be turned into a book document.
enum BookParsingError: Error, Equatable {
    case notUTF8(URL)
}
