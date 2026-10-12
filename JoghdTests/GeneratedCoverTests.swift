import Foundation
import Testing

@testable import Joghd

struct GeneratedCoverTests {
    @Test
    func hueIsDerivedDeterministicallyFromTheTitle() {
        let cover = GeneratedCover(title: "Dune")
        #expect(cover.hue == 59.0 / 360.0)
    }

    @Test
    func hueDoesNotDependOnTheAuthor() {
        let authored = GeneratedCover(title: "Dune", author: "Frank Herbert")
        let anonymous = GeneratedCover(title: "Dune")
        #expect(authored.hue == anonymous.hue)
    }

    @Test
    func differentTitlesGetDifferentHues() {
        #expect(GeneratedCover(title: "Dune").hue == 59.0 / 360.0)
        #expect(GeneratedCover(title: "Foundation").hue == 252.0 / 360.0)
    }

    @Test
    func hueStaysInTheUnitRangeForAnyTitle() {
        let titles = ["", "A Tiny Book", "🦇", String(repeating: "long ", count: 200)]
        for title in titles {
            let hue = GeneratedCover(title: title).hue
            #expect(hue >= 0 && hue < 1)
        }
    }

    @Test
    func keepsTitleAndOptionalAuthor() {
        let cover = GeneratedCover(title: "Dune", author: "Frank Herbert")
        #expect(cover.title == "Dune")
        #expect(cover.author == "Frank Herbert")
        #expect(GeneratedCover(title: "Dune").author == nil)
    }
}
