import Foundation

struct EpubBookParser {
    func parse(_ data: Data) throws -> BookDocument {
        let archive = try ZipArchive(data: data)

        let container = try EpubContainer.parse(try text(of: "META-INF/container.xml", in: archive))
        let package = try EpubPackage.parse(
            try text(of: container.packagePath, in: archive),
            packagePath: container.packagePath
        )

        let chapters = try package.spine.map { path in
            try EpubChapterScanner.scan(try text(of: path, in: archive))
        }

        return BookDocument(title: package.title, author: package.author, chapters: chapters)
    }

    func parse(contentsOf url: URL) throws -> BookDocument {
        try parse(try Data(contentsOf: url))
    }

    private func text(of path: String, in archive: ZipArchive) throws -> String {
        guard let data = try archive.data(for: path), let text = String(data: data, encoding: .utf8)
        else {
            throw BookParsingError.missingEpubEntry(path)
        }
        return text
    }
}
