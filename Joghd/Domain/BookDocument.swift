struct BookDocument: Equatable, Sendable {
    var title: String?
    var author: String?
    var chapters: [Chapter]
}
