import Foundation

enum EpubCoverFixture {
    static func epub(
        manifest: [(id: String, href: String)] = [(id: "a", href: "a.xhtml")],
        spine: [String] = ["a"],
        properties: [String: String] = [:],
        metaCoverID: String? = nil,
        resources: [(String, Data)] = []
    ) -> Data {
        let document = EpubFixture.package(
            manifest: manifest,
            spine: spine,
            properties: properties,
            metaCoverID: metaCoverID
        )
        var entries: [(String, Data)] = []
        entries.append(("META-INF/container.xml", Data(EpubFixture.container.utf8)))
        entries.append(("OEBPS/content.opf", Data(document.utf8)))
        entries.append(
            ("OEBPS/a.xhtml", Data(EpubFixture.chapter(title: "A", body: "<p>Body</p>").utf8))
        )
        entries.append(contentsOf: resources)
        return EpubFixture.zipBytes(entries)
    }
}
