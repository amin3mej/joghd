import Foundation

struct EpubPackage {
    var title: String?
    var author: String?
    var spine: [String]

    static func parse(_ xml: String, packagePath: String) throws -> Self {
        let tree = try XMLTreeBuilder.parse(xml)
        let manifestElement = tree.firstElement(named: "manifest")
        guard let spineElement = tree.firstElement(named: "spine"), let manifestElement else {
            throw BookParsingError.malformedEpub
        }

        var hrefs: [String: String] = [:]
        for item in manifestElement.childElements {
            guard let id = item.attribute("id"), let href = item.attribute("href") else {
                continue
            }
            hrefs[id] = href
        }

        let directory = packagePath.split(separator: "/").dropLast().joined(separator: "/")
        let order = try spineElement.childElements.compactMap { itemref -> String? in
            guard case .element(let name, _, _) = itemref, name == "itemref",
                let idref = itemref.attribute("idref")
            else {
                return nil
            }
            guard let href = hrefs[idref] else {
                throw BookParsingError.malformedEpub
            }
            return EpubPath.resolve(href, relativeTo: directory)
        }

        return Self(
            title: value(in: tree.firstElement(named: "metadata"), named: "title"),
            author: value(in: tree.firstElement(named: "metadata"), named: "creator"),
            spine: order
        )
    }

    private static func value(in metadata: XMLTree?, named name: String) -> String? {
        for element in metadata?.childElements ?? [] {
            guard case .element(let elementName, _, _) = element, elementName == name else {
                continue
            }
            let value = element.textContent.trimmingCharacters(in: .whitespacesAndNewlines)
            if !value.isEmpty {
                return value
            }
        }
        return nil
    }
}
