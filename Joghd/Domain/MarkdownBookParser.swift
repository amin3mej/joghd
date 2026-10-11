import Foundation

struct MarkdownBookParser {
    private struct FrontMatter {
        var title: String?
        var author: String?
    }

    private static let minimumQuotedLength = 2

    func parse(_ markdown: String) -> BookDocument {
        var lines = lines(of: markdown)
        let frontMatter = takeFrontMatter(&lines)
        var scanner = MarkdownBookScanner(lines: lines)
        return BookDocument(
            title: frontMatter.title,
            author: frontMatter.author,
            chapters: scanner.scan()
        )
    }

    func parse(contentsOf url: URL) throws -> BookDocument {
        let data = try Data(contentsOf: url)
        guard let markdown = String(data: data, encoding: .utf8) else {
            throw BookParsingError.notUTF8(url)
        }
        return parse(markdown)
    }

    private func lines(of markdown: String) -> [String] {
        markdown
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .components(separatedBy: "\n")
    }

    private func takeFrontMatter(_ lines: inout [String]) -> FrontMatter {
        let divider = "---"
        guard lines.first?.trimmingCharacters(in: .whitespaces) == divider else {
            return FrontMatter()
        }
        guard
            let closing = lines.dropFirst().firstIndex(where: { line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                return trimmed == divider || trimmed == "..."
            })
        else {
            return FrontMatter()
        }
        guard lines[1..<closing].contains(where: { $0.contains(":") }) else {
            return FrontMatter()
        }

        var frontMatter = FrontMatter()
        for line in lines[1..<closing] {
            guard let colon = line.firstIndex(of: ":") else {
                continue
            }
            let key = line[..<colon].trimmingCharacters(in: .whitespaces).lowercased()
            let rawValue = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
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

    private func unquoted(_ value: String) -> String {
        guard value.count >= Self.minimumQuotedLength,
            let first = value.first, first == "\"" || first == "'",
            value.last == first
        else {
            return value
        }
        return String(value.dropFirst().dropLast())
    }
}
