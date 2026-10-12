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
    func coverImageExtractsTheCoverWithoutParsingChapters() throws {
        let cover = CoverFixture.imageData(width: 8, height: 12)
        let package = EpubFixture.package(
            manifest: [(id: "a", href: "a.xhtml"), (id: "cover", href: "cover.png")],
            spine: ["a"],
            properties: ["cover": "cover-image"]
        )
        var entries: [(String, Data)] = []
        entries.append(("META-INF/container.xml", Data(EpubFixture.container.utf8)))
        entries.append(("OEBPS/content.opf", Data(package.utf8)))
        entries.append(("OEBPS/a.xhtml", Data("<html><head></head></html>".utf8)))
        entries.append(("OEBPS/cover.png", cover))
        let data = EpubFixture.zipBytes(entries)

        let extracted = try parser.coverImage(data)

        #expect(extracted == cover)
    }

    @Test
    func coverImageWithoutACoverDeclarationReturnsNil() throws {
        let data = EpubCoverFixture.epub()

        let extracted = try parser.coverImage(data)

        #expect(extracted == nil)
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
