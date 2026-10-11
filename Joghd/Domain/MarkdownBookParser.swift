import Foundation

struct MarkdownBookParser {
    private static func lines(of markdown: String) -> [String] {
        markdown
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .components(separatedBy: "\n")
    }

    private static func chapters(from blocks: [Block]) -> [Chapter] {
        var chapters: [Chapter] = []
        var title: String?
        var isOpen = false
        var current: [Block] = []
        var sawTopLevelHeading = false

        func close() {
            guard isOpen || !current.isEmpty else {
                return
            }
            chapters.append(Chapter(title: title, blocks: current))
            title = nil
            isOpen = false
            current = []
        }

        for block in blocks {
            guard case .heading(level: 1, text: let text) = block else {
                current.append(block)
                continue
            }
            close()
            sawTopLevelHeading = true
            let plain = text.plainText
            title = plain.isEmpty ? nil : plain
            isOpen = true
        }
        close()

        if !sawTopLevelHeading, chapters.isEmpty {
            chapters.append(Chapter(title: nil, blocks: []))
        }
        return chapters
    }

    func parse(_ markdown: String) -> BookDocument {
        var lines = Self.lines(of: markdown)
        let frontMatter = MarkdownFrontMatter.take(&lines)
        return BookDocument(
            title: frontMatter.title,
            author: frontMatter.author,
            chapters: Self.chapters(from: MarkdownBlockScanner.scan(lines))
        )
    }

    func parse(contentsOf url: URL) throws -> BookDocument {
        let data = try Data(contentsOf: url)
        guard let markdown = String(data: data, encoding: .utf8) else {
            throw BookParsingError.notUTF8(url)
        }
        return parse(markdown)
    }
}
