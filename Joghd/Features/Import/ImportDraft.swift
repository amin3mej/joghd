import Foundation

struct ImportDraft: Identifiable, Hashable {
    let id: UUID
    let source: URL
    let format: LibraryEntry.TextFormat
    var title: String
    var author: String

    init(
        id: UUID = UUID(),
        source: URL,
        format: LibraryEntry.TextFormat,
        title: String,
        author: String = ""
    ) {
        self.id = id
        self.source = source
        self.format = format
        self.title = title
        self.author = author
    }
}
