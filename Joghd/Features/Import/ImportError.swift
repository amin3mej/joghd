import Foundation

enum ImportError: Error, LocalizedError, Equatable {
    case unsupportedFormat

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat:
            "That file can't be imported."
        }
    }
}
