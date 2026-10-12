import Foundation

enum ReaderError: LocalizedError, Equatable {
    case unsupportedFormat

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat:
            "This book can't be opened."
        }
    }
}
