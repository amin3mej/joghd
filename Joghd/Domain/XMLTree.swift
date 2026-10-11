import Foundation

indirect enum XMLTree {
    case element(name: String, attributes: [String: String], children: [Self])
    case text(String)

    var elementName: String? {
        guard case .element(let name, _, _) = self else {
            return nil
        }
        return name
    }

    var attributes: [String: String] {
        guard case .element(_, let attributes, _) = self else {
            return [:]
        }
        return attributes
    }

    var text: String? {
        guard case .text(let value) = self else {
            return nil
        }
        return value
    }

    var childElements: [Self] {
        guard case .element(_, _, let children) = self else {
            return []
        }
        return children
    }

    var textContent: String {
        if let value = text {
            return value
        }
        return childElements.map(\.textContent).joined()
    }

    func attribute(_ name: String) -> String? {
        let values = attributes
        if let value = values[name] {
            return value
        }
        return values.first { key, _ in key.hasSuffix(":\(name)") }?.value
    }

    func firstElement(named name: String) -> Self? {
        if elementName == name {
            return self
        }
        for child in childElements {
            if let found = child.firstElement(named: name) {
                return found
            }
        }
        return nil
    }
}
