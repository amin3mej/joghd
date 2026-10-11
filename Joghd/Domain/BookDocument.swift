import Foundation

/// A book expressed as a structured text model: chapters of blocks. The Reader
/// lays this out into pages; Import validates a file by opening it into one.
/// See ADR-0001.
struct BookDocument: Equatable, Sendable {
    var title: String?
    var author: String?
    var chapters: [Chapter]
}

/// A top-level division of a book. Its title comes from the top-level heading
/// that opened it, or is `nil` for content that preceded any heading.
struct Chapter: Equatable, Sendable {
    var title: String?
    var blocks: [Block]
}

/// A unit of a chapter's text. Inline emphasis is carried on `InlineText`.
enum Block: Equatable, Sendable {
    case heading(level: Int, text: InlineText)
    case paragraph(InlineText)
    case quote(InlineText)
    case listItem(InlineText)
    case codeBlock(String)
    case divider
}

/// A run of inline text with its emphasis. Runs are kept in reading order and
/// concatenate back to the original plain text.
struct InlineText: Equatable, Sendable {
    struct Run: Equatable, Sendable {
        var text: String
        var isBold: Bool
        var isItalic: Bool

        init(text: String, isBold: Bool = false, isItalic: Bool = false) {
            self.text = text
            self.isBold = isBold
            self.isItalic = isItalic
        }
    }

    var runs: [Run]

    init(runs: [Run]) {
        self.runs = runs
    }

    /// Unemphasized text in a single run.
    init(_ string: String) {
        self.init(runs: [Run(text: string)])
    }

    var plainText: String {
        runs.map(\.text).joined()
    }
}
