import Foundation

enum ImportError: Error, LocalizedError, Equatable {
    case unreadableFile
    case unsupportedFormat

    var errorDescription: String? {
        switch self {
        case .unreadableFile:
            "That file couldn't be opened."

        case .unsupportedFormat:
            "That file can't be imported."
        }
    }
}
