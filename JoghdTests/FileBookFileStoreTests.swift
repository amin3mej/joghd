import Foundation
import Testing

@testable import Joghd

@MainActor
struct FileBookFileStoreTests {
    private let originalBytes = Data([0x50, 0x4B, 0x03, 0x04, 0x0A])

    private func makeSourceFile(named name: String = "Dune.epub") throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(name)
        try originalBytes.write(to: url)
        return url
    }

    private func makeStore() -> (store: FileBookFileStore, directory: URL) {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        return (FileBookFileStore(directoryURL: directory), directory)
    }

    @Test
    func storedFileMatchesOriginalBytes() async throws {
        let source = try makeSourceFile()
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }
        let (store, directory) = makeStore()
        defer { try? FileManager.default.removeItem(at: directory) }

        let stored = try await store.store(source, for: LibraryEntry(title: "Dune", format: .epub))

        #expect(try Data(contentsOf: stored) == originalBytes)
    }

    @Test
    func storedFileKeepsOriginalName() async throws {
        let source = try makeSourceFile(named: "Notes.markdown")
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }
        let (store, directory) = makeStore()
        defer { try? FileManager.default.removeItem(at: directory) }

        let stored = try await store.store(
            source, for: LibraryEntry(title: "Notes", format: .markdown)
        )

        #expect(stored.lastPathComponent == "Notes.markdown")
    }

    @Test
    func storingLeavesOriginalUnmodified() async throws {
        let source = try makeSourceFile()
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }
        let (store, directory) = makeStore()
        defer { try? FileManager.default.removeItem(at: directory) }

        _ = try await store.store(source, for: LibraryEntry(title: "Dune", format: .epub))

        #expect(try Data(contentsOf: source) == originalBytes)
    }

    @Test
    func storedFileForStoredEntryReturnsTheStoredBytes() async throws {
        let source = try makeSourceFile()
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }
        let (store, directory) = makeStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        let entry = LibraryEntry(title: "Dune", format: .epub)

        _ = try await store.store(source, for: entry)
        let resolved = try store.storedFile(for: entry)

        #expect(try Data(contentsOf: resolved) == originalBytes)
    }

    @Test
    func storedFileForAnEntryThatWasNeverStoredThrows() throws {
        let (store, directory) = makeStore()
        defer { try? FileManager.default.removeItem(at: directory) }

        #expect(throws: BookFileError.missingFile) {
            _ = try store.storedFile(for: LibraryEntry(title: "Dune", format: .epub))
        }
    }

    @Test
    func removingEntryDeletesItsStoredFile() async throws {
        let source = try makeSourceFile()
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }
        let (store, directory) = makeStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        let entry = LibraryEntry(title: "Dune", format: .epub)
        let stored = try await store.store(source, for: entry)

        try store.remove(for: entry)

        #expect(!FileManager.default.fileExists(atPath: stored.path))
        #expect(!FileManager.default.fileExists(atPath: stored.deletingLastPathComponent().path))
    }

    @Test
    func removingEntryWithoutStoredFileSucceeds() throws {
        let (store, directory) = makeStore()
        defer { try? FileManager.default.removeItem(at: directory) }

        #expect(throws: Never.self) {
            try store.remove(for: LibraryEntry(title: "Dune", format: .epub))
        }
    }

    @Test
    func removingOneEntryLeavesAnotherEntryFile() async throws {
        let source = try makeSourceFile()
        defer { try? FileManager.default.removeItem(at: source.deletingLastPathComponent()) }
        let (store, directory) = makeStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        let kept = LibraryEntry(title: "Dune", format: .epub)
        let removed = LibraryEntry(title: "Foundation", format: .epub)
        let keptFile = try await store.store(source, for: kept)
        let removedFile = try await store.store(source, for: removed)

        try store.remove(for: removed)

        #expect(FileManager.default.fileExists(atPath: keptFile.path))
        #expect(!FileManager.default.fileExists(atPath: removedFile.path))
    }
}
