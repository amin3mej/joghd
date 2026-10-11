import Foundation

enum EpubPath {
    static func resolve(_ href: String, relativeTo directory: String) -> String {
        var target = href
        if let fragment = target.firstIndex(of: "#") {
            target = String(target[..<fragment])
        }
        if let query = target.firstIndex(of: "?") {
            target = String(target[..<query])
        }
        target = target.removingPercentEncoding ?? target

        var components =
            target.hasPrefix("/") ? [] : directory.split(separator: "/").map(String.init)
        components.append(contentsOf: target.split(separator: "/").map(String.init))

        var resolved: [String] = []
        for component in components {
            switch component {
            case "", ".":
                continue

            case "..":
                if !resolved.isEmpty {
                    resolved.removeLast()
                }

            default:
                resolved.append(component)
            }
        }
        return resolved.joined(separator: "/")
    }
}
