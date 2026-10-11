import UniformTypeIdentifiers

enum ImportFileTypes {
    static let markdown = UTType(importedAs: "net.daringfireball.markdown")
    static let allowed: [UTType] = [.epub, markdown]
}
