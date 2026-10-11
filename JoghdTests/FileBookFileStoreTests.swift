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
}
