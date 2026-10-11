import Foundation

enum XMLTreeBuilder {
    private struct Frame {
        let name: String
        let attributes: [String: String]
        var children: [XMLTree]
    }

    private final class TreeDelegate: NSObject, XMLParserDelegate {
        var root: XMLTree?
        private var stack: [Frame] = []

        func parser(
            _: XMLParser,
            didStartElement elementName: String,
            namespaceURI _: String?,
            qualifiedName _: String?,
            attributes attributeDict: [String: String] = [:]
        ) {
            stack.append(Frame(name: elementName, attributes: attributeDict, children: []))
        }

        func parser(
            _: XMLParser,
            didEndElement _: String,
            namespaceURI _: String?,
            qualifiedName _: String?
        ) {
            guard let finished = stack.popLast() else {
                return
            }
            let node = XMLTree.element(
                name: finished.name,
                attributes: finished.attributes,
                children: finished.children
            )
            if stack.isEmpty {
                root = node
            } else {
                stack[stack.count - 1].children.append(node)
            }
        }

        func parser(_: XMLParser, foundCharacters string: String) {
            guard !stack.isEmpty else {
                return
            }
            stack[stack.count - 1].children.append(.text(string))
        }
    }

    static func parse(_ string: String) throws -> XMLTree {
        let delegate = TreeDelegate()
        let parser = XMLParser(data: Data(string.utf8))
        parser.delegate = delegate
        parser.shouldProcessNamespaces = true
        guard parser.parse(), let root = delegate.root else {
            throw BookParsingError.malformedEpub
        }
        return root
    }
}
