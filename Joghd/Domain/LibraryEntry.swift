import Foundation

/// A book in the reader's collection, which may contain a text version, an
/// audio version, or both. V1 imports text only.
struct LibraryEntry: Identifiable, Hashable, Codable {
    enum TextFormat: String, Codable, Hashable, CaseIterable {
        case epub
        case markdown
        case pdf
    }

    let id: UUID
    var title: String
    var author: String?
    var format: TextFormat
    var importedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        author: String? = nil,
        format: TextFormat,
        importedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.format = format
        self.importedAt = importedAt
    }
}
