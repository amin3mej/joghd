import Foundation

enum EpubInlineText {
    private static let blockLevelElements = Set(
        "p div blockquote li ul ol section article h1 h2 h3 h4 h5 h6"
            .split(separator: " ")
            .map(String.init)
    )

    static func parse(_ nodes: [XMLTree]) -> InlineText {
        InlineText(runs: normalized(runs(in: nodes, isBold: false, isItalic: false)))
    }

    private static func runs(
        in nodes: [XMLTree],
        isBold: Bool,
        isItalic: Bool
    ) -> [InlineText.Run] {
        var result: [InlineText.Run] = []
        for node in nodes {
            if let text = node.text {
                result.append(InlineText.Run(text: text, isBold: isBold, isItalic: isItalic))
                continue
            }
            guard let name = node.elementName else {
                continue
            }
            switch name.lowercased() {
            case "em", "i":
                result += runs(in: node.childElements, isBold: isBold, isItalic: true)

            case "strong", "b":
                result += runs(in: node.childElements, isBold: true, isItalic: isItalic)

            case "script", "style":
                continue

            case "br":
                append(" ", isBold: isBold, isItalic: isItalic, to: &result)

            default:
                let isBlock = blockLevelElements.contains(name.lowercased())
                if isBlock, !result.isEmpty {
                    append(" ", isBold: isBold, isItalic: isItalic, to: &result)
                }
                result += runs(in: node.childElements, isBold: isBold, isItalic: isItalic)
                if isBlock {
                    append(" ", isBold: isBold, isItalic: isItalic, to: &result)
                }
            }
        }
        return result
    }

    private static func normalized(_ runs: [InlineText.Run]) -> [InlineText.Run] {
        var result: [InlineText.Run] = []
        var previousWasSpace = true
        for run in runs {
            for character in run.text {
                if character.isWhitespace {
                    if !previousWasSpace {
                        appendRun(" ", of: run, to: &result)
                        previousWasSpace = true
                    }
                    continue
                }
                previousWasSpace = false
                appendRun(String(character), of: run, to: &result)
            }
        }
        guard let last = result.last, last.text.hasSuffix(" ") else {
            return result
        }
        var trimmed = result
        var final = trimmed.removeLast()
        final.text = String(final.text.dropLast())
        if !final.text.isEmpty {
            trimmed.append(final)
        }
        return trimmed
    }

    private static func append(
        _ text: String,
        isBold: Bool,
        isItalic: Bool,
        to result: inout [InlineText.Run]
    ) {
        result.append(InlineText.Run(text: text, isBold: isBold, isItalic: isItalic))
    }

    private static func appendRun(
        _ text: String,
        of run: InlineText.Run,
        to result: inout [InlineText.Run]
    ) {
        if var last = result.last, last.isBold == run.isBold, last.isItalic == run.isItalic {
            last.text += text
            result[result.count - 1] = last
        } else {
            result.append(InlineText.Run(text: text, isBold: run.isBold, isItalic: run.isItalic))
        }
    }
}
