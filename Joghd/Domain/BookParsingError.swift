import Foundation

enum BookParsingError: Error, Equatable {
    case malformedEpub
    case missingEpubEntry(String)
    case notUTF8(URL)
}
