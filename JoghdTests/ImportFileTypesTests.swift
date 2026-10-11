import Testing
import UniformTypeIdentifiers

@testable import Joghd

struct ImportFileTypesTests {
    @Test
    func offersEpubAndMarkdown() {
        let identifiers = ImportFileTypes.allowed.map(\.identifier)
        #expect(identifiers.contains(UTType.epub.identifier))
        #expect(identifiers.contains("net.daringfireball.markdown"))
    }

    @Test
    func doesNotOfferPDF() {
        #expect(!ImportFileTypes.allowed.contains(.pdf))
    }
}
