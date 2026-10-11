import Foundation

enum MarkdownInlineText {
    private struct EmphasisMatch {
        let isBold: Bool
        let isItalic: Bool
        let content: ArraySlice<Character>
        let end: Int
    }

    private static let maxMarkerLength = 3
    private static let boldMarkerLength = 2

    static func parse(_ string: String) -> InlineText {
        InlineText(runs: coalesce(parseRuns(Array(string))))
    }

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
        var cursor = 0

        func flush() {
            guard !buffer.isEmpty else {
                return
            }
            runs.append(InlineText.Run(text: buffer, isBold: bold, isItalic: italic))
            buffer = ""
        }

        while cursor < chars.count {
            let character = chars[cursor]

            if let dropped = matchDropped(chars, at: cursor) {
                cursor = dropped
                continue
            }

            if let link = matchLink(chars, openingBracket: cursor) {
                flush()
                runs.append(
                    contentsOf: parseRuns(Array(link.label), isBold: bold, isItalic: italic)
                )
                cursor = link.end
                continue
            }

            if let emphasis = matchEmphasis(chars, at: cursor) {
                flush()
                runs.append(
                    contentsOf: parseRuns(
                        Array(emphasis.content),
                        isBold: bold || emphasis.isBold,
                        isItalic: italic || emphasis.isItalic
                    )
                )
                cursor = emphasis.end
                continue
            }

            buffer.append(character)
            cursor += 1
        }
        flush()
        return runs
    }

    private static func matchDropped(_ chars: [Character], at index: Int) -> Int? {
        if chars[index] == "!", index + 1 < chars.count, chars[index + 1] == "[" {
            return matchLink(chars, openingBracket: index + 1)?.end
        }
        if chars[index] == "[", index + 1 < chars.count, chars[index + 1] == "^" {
            return matchClosing(chars, from: index, open: "[", close: "]")
        }
        return nil
    }

    private static func matchLink(
        _ chars: [Character],
        openingBracket: Int
    ) -> (label: String, end: Int)? {
        guard openingBracket < chars.count, chars[openingBracket] == "[" else {
            return nil
        }
        guard
            let labelEnd = matchClosing(chars, from: openingBracket, open: "[", close: "]"),
            labelEnd < chars.count, chars[labelEnd] == "(",
            let targetEnd = matchClosing(chars, from: labelEnd, open: "(", close: ")")
        else {
            return nil
        }
        let label = String(chars[(openingBracket + 1)..<(labelEnd - 1)])
        return (label, targetEnd)
    }

    private static func matchClosing(
        _ chars: [Character],
        from start: Int,
        open: Character,
        close: Character
    ) -> Int? {
        var depth = 0
        var cursor = start
        while cursor < chars.count {
            if chars[cursor] == open {
                depth += 1
            } else if chars[cursor] == close {
                depth -= 1
                if depth == 0 {
                    return cursor + 1
                }
            }
            cursor += 1
        }
        return nil
    }

    private static func matchEmphasis(_ chars: [Character], at index: Int) -> EmphasisMatch? {
        guard index < chars.count, chars[index] == "*" || chars[index] == "_" else {
            return nil
        }
        let marker = chars[index]
        var run = 0
        while index + run < chars.count, chars[index + run] == marker, run < maxMarkerLength {
            run += 1
        }
        let length = min(run, maxMarkerLength)
        let afterOpening = index + length
        guard afterOpening < chars.count, !chars[afterOpening].isWhitespace else {
            return nil
        }
        if marker == "_", index > 0, chars[index - 1].isLetter || chars[index - 1].isNumber {
            return nil
        }

        var closer = afterOpening
        while closer < chars.count {
            guard chars[closer] == marker else {
                closer += 1
                continue
            }
            let closerRun = emphasisRun(chars, from: closer)
            if isCloser(chars, at: closer, run: closerRun, length: length, marker: marker) {
                return EmphasisMatch(
                    isBold: length >= boldMarkerLength,
                    isItalic: length != boldMarkerLength,
                    content: chars[afterOpening..<closer],
                    end: closer + length
                )
            }
            closer += closerRun
        }
        return nil
    }

    private static func emphasisRun(_ chars: [Character], from start: Int) -> Int {
        var run = 0
        while start + run < chars.count, chars[start + run] == chars[start] {
            run += 1
        }
        return run
    }

    private static func isCloser(
        _ chars: [Character],
        at index: Int,
        run: Int,
        length: Int,
        marker: Character
    ) -> Bool {
        guard run >= length, index > 0, !chars[index - 1].isWhitespace else {
            return false
        }
        if marker != "_" {
            return true
        }
        let afterRun = index + run
        guard afterRun < chars.count else {
            return true
        }
        return !chars[afterRun].isLetter && !chars[afterRun].isNumber
    }
}
