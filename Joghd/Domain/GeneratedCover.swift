import Foundation

struct GeneratedCover: Equatable, Hashable {
    private static let hueSteps = 360
    private static let fnvOffsetBasis: UInt32 = 2_166_136_261
    private static let fnvPrime: UInt32 = 16_777_619

    let title: String
    let author: String?
    let hue: Double

    init(title: String, author: String? = nil) {
        self.title = title
        self.author = author
        let step = Self.stableHash(title) % UInt32(Self.hueSteps)
        self.hue = Double(step) / Double(Self.hueSteps)
    }

    private static func stableHash(_ value: String) -> UInt32 {
        var hash = fnvOffsetBasis
        for byte in value.utf8 {
            hash ^= UInt32(byte)
            hash = hash &* fnvPrime
        }
        return hash
    }
}
