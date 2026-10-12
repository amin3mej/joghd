import Foundation

struct EpubPackage {
    private struct ManifestItem {
        let href: String
        let properties: String?
    }

    var title: String?
    var author: String?
    var spine: [String]
    var coverPath: String?

    static func parse(_ xml: String, packagePath: String) throws -> Self {
        let tree = try XMLTreeBuilder.parse(xml)
        let manifestElement = tree.firstElement(named: "manifest")
        guard let spineElement = tree.firstElement(named: "spine"), let manifestElement else {
            throw BookParsingError.malformedEpub
        }

        var manifest: [String: ManifestItem] = [:]
        for item in manifestElement.childElements {
            guard let id = item.attribute("id"), let href = item.attribute("href") else {
                continue
            }
            manifest[id] = ManifestItem(href: href, properties: item.attribute("properties"))
        }

        let directory = packagePath.split(separator: "/").dropLast().joined(separator: "/")
        let order = try spineElement.childElements.compactMap { itemref -> String? in
            guard let name = itemref.elementName, name == "itemref" else {
                return nil
            }
            guard itemref.attribute("linear")?.lowercased() != "no" else {
                return nil
            }
            guard let idref = itemref.attribute("idref") else {
                throw BookParsingError.malformedEpub
            }
            guard let href = manifest[idref]?.href else {
                throw BookParsingError.malformedEpub
            }
            return EpubPath.resolve(href, relativeTo: directory)
        }

        return Self(
            title: value(in: tree.firstElement(named: "metadata"), named: "title"),
            author: value(in: tree.firstElement(named: "metadata"), named: "creator"),
            spine: order,
            coverPath: coverPath(in: tree, manifest: manifest, directory: directory)
        )
    }

    private static func coverPath(
        in tree: XMLTree,
        manifest: [String: ManifestItem],
        directory: String
    ) -> String? {
        let designated = manifest.values.first { item in
            item.properties?.split(separator: " ").contains("cover-image") == true
        }
        if let designated {
            return EpubPath.resolve(designated.href, relativeTo: directory)
        }

        guard
            let id = coverID(in: tree.firstElement(named: "metadata")),
            let item = manifest[id]
        else {
            return nil
        }
        return EpubPath.resolve(item.href, relativeTo: directory)
    }

    private static func coverID(in metadata: XMLTree?) -> String? {
        for element in metadata?.childElements ?? [] {
            guard case .element(let name, _, _) = element, name == "meta" else {
                continue
            }
            guard element.attribute("name")?.lowercased() == "cover" else {
                continue
            }
            if let content = element.attribute("content"), !content.isEmpty {
                return content
            }
        }
        return nil
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
