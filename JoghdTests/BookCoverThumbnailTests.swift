import Foundation
import Testing

@testable import Joghd

struct BookCoverThumbnailTests {
    @Test
    func boundsALargeImage() throws {
        let original = CoverFixture.imageData(width: 2_000, height: 3_000)

        let thumbnail = try #require(BookCoverThumbnail.make(from: original))

        let size = try #require(CoverFixture.pixelSize(of: thumbnail))
        #expect(max(size.width, size.height) <= BookCoverThumbnail.maximumPixelSize)
    }

    @Test
    func keepsSmallImagesUsable() throws {
        let original = CoverFixture.imageData(width: 4, height: 6)

        let thumbnail = try #require(BookCoverThumbnail.make(from: original))

        let size = try #require(CoverFixture.pixelSize(of: thumbnail))
        #expect(size.width > 0 && size.height > 0)
    }

    @Test
    func rejectsDataThatIsNotAnImage() {
        #expect(BookCoverThumbnail.make(from: Data("not an image".utf8)) == nil)
    }

    @Test
    func rejectsEmptyData() {
        #expect(BookCoverThumbnail.make(from: Data()) == nil)
    }
}
