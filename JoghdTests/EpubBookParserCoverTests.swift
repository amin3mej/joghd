import Foundation
import Testing

@testable import Joghd

struct EpubBookParserCoverTests {
    private let parser = EpubBookParser()

    @Test
    func epub3CoverImagePropertySuppliesTheCoverBytes() throws {
        let cover = CoverFixture.imageData(width: 8, height: 12)
        let data = EpubCoverFixture.epub(
            manifest: [(id: "a", href: "a.xhtml"), (id: "cover", href: "images/cover.png")],
            properties: ["cover": "cover-image"],
            resources: [("OEBPS/images/cover.png", cover)]
        )

        let imported = try parser.importBook(data)

        #expect(imported.coverImage == cover)
    }

    @Test
    func epub3PropertiesMayListSeveralTokens() throws {
        let cover = CoverFixture.imageData(width: 8, height: 12)
        let data = EpubCoverFixture.epub(
            manifest: [(id: "a", href: "a.xhtml"), (id: "cover", href: "cover.png")],
            properties: ["cover": "svg cover-image"],
            resources: [("OEBPS/cover.png", cover)]
        )

        let imported = try parser.importBook(data)

        #expect(imported.coverImage == cover)
    }

    @Test
    func epub2CoverMetaSuppliesTheCoverBytes() throws {
        let cover = CoverFixture.imageData(width: 8, height: 12)
        let data = EpubCoverFixture.epub(
            manifest: [(id: "a", href: "a.xhtml"), (id: "cover-image", href: "cover.jpg")],
            metaCoverID: "cover-image",
            resources: [("OEBPS/cover.jpg", cover)]
        )

        let imported = try parser.importBook(data)

        #expect(imported.coverImage == cover)
    }

    @Test
    func coverHrefResolvesRelativeToThePackageDirectory() throws {
        let cover = CoverFixture.imageData(width: 8, height: 12)
        let data = EpubCoverFixture.epub(
            manifest: [(id: "a", href: "a.xhtml"), (id: "cover", href: "../Images/cover.png")],
            properties: ["cover": "cover-image"],
            resources: [("Images/cover.png", cover)]
        )

        let imported = try parser.importBook(data)

        #expect(imported.coverImage == cover)
    }

    @Test
    func absentCoverDeclarationsYieldNoCover() throws {
        let data = EpubCoverFixture.epub()

        let imported = try parser.importBook(data)

        #expect(imported.coverImage == nil)
    }

    @Test
    func declaredButMissingCoverResourceYieldsNoCoverAndStillParses() throws {
        let data = EpubCoverFixture.epub(
            manifest: [(id: "a", href: "a.xhtml"), (id: "cover", href: "missing.png")],
            properties: ["cover": "cover-image"]
        )

        let imported = try parser.importBook(data)

        #expect(imported.coverImage == nil)
        #expect(imported.document.chapters.count == 1)
    }

    @Test
    func coverMetaPointingAtAnUnknownManifestItemYieldsNoCover() throws {
        let data = EpubCoverFixture.epub(metaCoverID: "ghost")

        let imported = try parser.importBook(data)

        #expect(imported.coverImage == nil)
    }

    @Test
    func parsingStillSurfacesTheDocumentAlongsideTheCover() throws {
        let cover = CoverFixture.imageData(width: 8, height: 12)
        let data = EpubCoverFixture.epub(
            manifest: [(id: "a", href: "a.xhtml"), (id: "cover", href: "cover.png")],
            properties: ["cover": "cover-image"],
            resources: [("OEBPS/cover.png", cover)]
        )

        let imported = try parser.importBook(data)

        #expect(imported.document.title == "The Book")
        #expect(imported.document.chapters.map(\.title) == ["A"])
    }
}
