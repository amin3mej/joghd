import Foundation

struct MarkdownFrontMatter {
    private static let quotedLength = 2

    var title: String?
    var author: String?

    static func take(_ lines: inout [String]) -> Self {
        guard lines.first?.trimmingCharacters(in: .whitespaces) == "---" else {
            return Self()
        }
        guard
            let closing = lines.dropFirst().firstIndex(where: { line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                return trimmed == "---" || trimmed == "..."
            })
        else {
            return Self()
        }
        guard lines[1..<closing].contains(where: { line in line.contains(":") }) else {
            return Self()
        }

        var frontMatter = Self()
        for line in lines[1..<closing] {
            guard let colon = line.firstIndex(of: ":") else { continue }
            let key = line[..<colon].trimmingCharacters(in: .whitespaces).lowercased()
            let rawValue = line[line.index(after: colon)...]
                .trimmingCharacters(in: .whitespaces)
            let value = unquoted(rawValue)
            switch key {
            case "title":
                frontMatter.title = value.isEmpty ? nil : value

            case "author":
                frontMatter.author = value.isEmpty ? nil : value

            default:
                break
            }
        }

        lines = Array(lines[(closing + 1)...])
        return frontMatter
    }

    private static func unquoted(_ value: String) -> String {
        guard value.count >= quotedLength,
            let first = value.first,
            first == "\"" || first == "'",
            value.last == first
        else {
            return value
        }
        return String(value.dropFirst().dropLast())
    }
}
