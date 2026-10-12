import Foundation

struct Location: Hashable, Codable {
    static let charactersPerLocation = 128

    let characterOffset: Int

    init(characterOffset: Int) {
        self.characterOffset = max(0, characterOffset)
    }

    init(index: Int) {
        self.init(characterOffset: max(0, index) * Self.charactersPerLocation)
    }
}
