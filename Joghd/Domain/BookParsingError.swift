import Foundation

enum BookParsingError: Error, Equatable, LocalizedError {
    case malformedEpub
    case missingEpubEntry(String)
    case notUTF8(URL)

    var errorDescription: String? {
        switch self {
        case .malformedEpub:
            "This EPUB file is damaged."

        case .missingEpubEntry:
            "This EPUB file is incomplete."

        case .notUTF8:
            "This file isn't valid text."
        }
    }
}
