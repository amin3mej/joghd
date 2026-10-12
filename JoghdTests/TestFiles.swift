import Foundation

enum TestFiles {
    static func source(named name: String, contents: Data = Data()) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(name)
        try contents.write(to: url)
        return url
    }

    static func epub(
        named name: String = "Dune.epub",
        title: String? = "The Book",
        author: String? = "The Author"
    ) throws -> URL {
        let data = EpubFixture.zip {
            ("META-INF/container.xml", EpubFixture.container)
            (
                "OEBPS/content.opf",
                EpubFixture.package(
                    title: title,
                    author: author,
                    manifest: [(id: "a", href: "a.xhtml")],
                    spine: ["a"]
                )
            )
            ("OEBPS/a.xhtml", EpubFixture.chapter(title: "A", body: "<p>Body</p>"))
        }
        return try source(named: name, contents: data)
    }
}
