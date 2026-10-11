import Foundation

enum EpubChapterScanner {
    static func scan(_ xhtml: String) throws -> Chapter {
        let tree = try XMLTreeBuilder.parse(xhtml)
        let title = tree.firstElement(named: "title")?.textContent
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let body = tree.firstElement(named: "body") else {
            throw BookParsingError.malformedEpub
        }
        let bodyBlocks = blocks(in: body.childElements)
        return Chapter(title: title?.isEmpty == true ? nil : title, blocks: bodyBlocks)
    }

    private static func blocks(in nodes: [XMLTree]) -> [Block] {
        var result: [Block] = []
        for node in nodes {
            guard let name = node.elementName else {
                continue
            }
            let children = node.childElements
            switch name.lowercased() {
            case "h1", "h2", "h3", "h4", "h5", "h6":
                let text = EpubInlineText.parse(children)
                append(.heading(level: Int(name.dropFirst()) ?? 1, text: text), to: &result)

            case "p":
                append(.paragraph(EpubInlineText.parse(children)), to: &result)

            case "blockquote":
                append(.quote(EpubInlineText.parse(children)), to: &result)

            case "li":
                var nestedLists: [XMLTree] = []
                let itemChildren = separatingLists(in: children, into: &nestedLists)
                append(.listItem(EpubInlineText.parse(itemChildren)), to: &result)
                result += blocks(in: nestedLists)

            case "ul", "ol", "div", "section", "article", "main", "header", "footer", "nav",
                "aside", "figure":
                result += blocks(in: children)

            default:
                continue
            }
        }
        return result
    }

    private static func separatingLists(
        in nodes: [XMLTree], into lists: inout [XMLTree]
    ) -> [XMLTree] {
        nodes.compactMap { node in
            guard let name = node.elementName else {
                return node
            }
            if name.lowercased() == "ul" || name.lowercased() == "ol" {
                lists.append(node)
                return nil
            }
            return .element(
                name: name,
                attributes: node.attributes,
                children: separatingLists(in: node.childElements, into: &lists)
            )
        }
    }

    private static func append(_ block: Block, to blocks: inout [Block]) {
        switch block {
        case .heading(_, let text), .listItem(let text), .paragraph(let text), .quote(let text):
            guard !text.plainText.isEmpty else {
                return
            }

        case .codeBlock, .divider:
            break
        }
        blocks.append(block)
    }
}
