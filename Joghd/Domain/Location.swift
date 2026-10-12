import Foundation

struct Location: Hashable, Codable {
    static let charactersPerLocation = 128

    let index: Int

    var characterOffset: Int {
        index * Self.charactersPerLocation
    }

    var lastCharacterOffset: Int {
        characterOffset + Self.charactersPerLocation - 1
    }

    init(index: Int) {
        self.index = max(0, index)
    }

    init(containing characterOffset: Int) {
        self.init(index: max(0, characterOffset) / Self.charactersPerLocation)
    }
}
