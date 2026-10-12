import Foundation

enum BookFileError: LocalizedError, Equatable {
    case missingFile

    var errorDescription: String? {
        switch self {
        case .missingFile:
            "This book's file is missing."
        }
    }
}
