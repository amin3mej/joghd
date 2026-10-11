import Foundation

enum MarkdownInlineParser {
    private struct EmphasisMatch {
        let isBold: Bool
        let isItalic: Bool
        let content: ArraySlice<Character>
        let end: Int
    }

    private static let maximumMarkerLength = 3
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
        _ characters: [Character],
        isBold: Bool = false,
        isItalic: Bool = false
    ) -> [InlineText.Run] {
        var runs: [InlineText.Run] = []
        var buffer = ""
        var cursor = 0

        func flush() {
            guard !buffer.isEmpty else {
                return
            }
            runs.append(InlineText.Run(text: buffer, isBold: isBold, isItalic: isItalic))
            buffer = ""
        }

        while cursor < characters.count {
            let character = characters[cursor]

            if character == "!", let end = imageEnd(characters, at: cursor) {
                cursor = end
                continue
            }

            if character == "[" {
                if let end = footnoteEnd(characters, at: cursor) {
                    cursor = end
                    continue
                }
                if let link = matchLink(characters, openingBracket: cursor) {
                    flush()
                    appendRuns(link.label, isBold: isBold, isItalic: isItalic, to: &runs)
                    cursor = link.end
                    continue
                }
            }

            if character == "*" || character == "_" {
                if let emphasis = matchEmphasis(characters, at: cursor) {
                    flush()
                    appendParsed(
                        emphasis.content,
                        isBold: isBold || emphasis.isBold,
                        isItalic: isItalic || emphasis.isItalic,
                        to: &runs
                    )
                    cursor = emphasis.end
                    continue
                }
            }

            buffer.append(character)
            cursor += 1
        }
        flush()
        return runs
    }

    private static func appendRuns(
        _ label: String,
        isBold: Bool,
        isItalic: Bool,
        to runs: inout [InlineText.Run]
    ) {
        runs.append(contentsOf: parseRuns(Array(label), isBold: isBold, isItalic: isItalic))
    }

    private static func appendParsed(
        _ characters: ArraySlice<Character>,
        isBold: Bool,
        isItalic: Bool,
        to runs: inout [InlineText.Run]
    ) {
        runs.append(contentsOf: parseRuns(Array(characters), isBold: isBold, isItalic: isItalic))
    }

    private static func imageEnd(_ characters: [Character], at cursor: Int) -> Int? {
        guard cursor + 1 < characters.count, characters[cursor + 1] == "[" else {
            return nil
        }
        return matchLink(characters, openingBracket: cursor + 1)?.end
    }

    private static func footnoteEnd(_ characters: [Character], at cursor: Int) -> Int? {
        guard cursor + 1 < characters.count, characters[cursor + 1] == "^" else {
            return nil
        }
        return matchClosing(characters, from: cursor, open: "[", close: "]")
    }

    private static func matchLink(
        _ characters: [Character],
        openingBracket: Int
    ) -> (label: String, end: Int)? {
        guard let labelEnd = matchClosing(characters, from: openingBracket, open: "[", close: "]"),
            labelEnd < characters.count, characters[labelEnd] == "(",
            let targetEnd = matchClosing(characters, from: labelEnd, open: "(", close: ")")
        else {
            return nil
        }

        let label = String(characters[(openingBracket + 1)..<(labelEnd - 1)])
        return (label, targetEnd)
    }

    private static func matchClosing(
        _ characters: [Character],
        from start: Int,
        open: Character,
        close: Character
    ) -> Int? {
        var depth = 0
        var cursor = start
        while cursor < characters.count {
            if characters[cursor] == open {
                depth += 1
            } else if characters[cursor] == close {
                depth -= 1
                if depth == 0 {
                    return cursor + 1
                }
            }
            cursor += 1
        }
        return nil
    }

    private static func matchEmphasis(_ characters: [Character], at index: Int) -> EmphasisMatch? {
        let marker = characters[index]
        let length = characters[index...].prefix(maximumMarkerLength).prefix { $0 == marker }.count

        let afterOpening = index + length
        guard afterOpening < characters.count, !characters[afterOpening].isWhitespace else {
            return nil
        }

        let isInsideWord =
            index > 0 && (characters[index - 1].isLetter || characters[index - 1].isNumber)
        if marker == "_", isInsideWord {
            return nil
        }

        var closer = afterOpening
        while closer < characters.count {
            guard characters[closer] == marker else {
                closer += 1
                continue
            }
            var closerRun = 0
            while closer + closerRun < characters.count, characters[closer + closerRun] == marker {
                closerRun += 1
            }
            let precededByNonSpace = closer > 0 && !characters[closer - 1].isWhitespace
            let wordBoundary =
                marker != "_"
                || closer + closerRun >= characters.count
                || !(characters[closer + closerRun].isLetter
                    || characters[closer + closerRun].isNumber)
            if closerRun >= length, precededByNonSpace, wordBoundary {
                return EmphasisMatch(
                    isBold: length >= boldMarkerLength,
                    isItalic: length == 1 || length == maximumMarkerLength,
                    content: characters[afterOpening..<closer],
                    end: closer + length
                )
            }
            closer += closerRun
        }
        return nil
    }
}
