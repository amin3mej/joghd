// SPDX-License-Identifier: MPL-2.0
import Foundation
import Observation

/// Owns the reader's on-device library. V1 keeps everything local; no account,
/// server upload, or cloud processing.
@Observable
final class LibraryStore {
    private(set) var entries: [LibraryEntry] = []

    func add(_ entry: LibraryEntry) {
        entries.append(entry)
    }
}
