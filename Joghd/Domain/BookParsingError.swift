import Foundation

enum BookParsingError: Error, Equatable {
    case notUTF8(URL)
}
