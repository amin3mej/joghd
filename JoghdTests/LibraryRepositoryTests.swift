import Foundation
import Testing

@testable import Joghd

@MainActor
struct LibraryRepositoryTests {
    @Test
    func upsertedEntrySurvivesReopeningRepository() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("library.json")
        let entry = LibraryEntry(
            title: "Dune",
            author: "Frank Herbert",
            format: .epub,
            importedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let repository: any LibraryRepository = FileLibraryRepository(documentURL: url)
        try repository.upsert(entry)

        let reopened: any LibraryRepository = FileLibraryRepository(documentURL: url)
        #expect(try reopened.entries() == [entry])
    }

    @Test
    func upsertReplacesEntryWithSameID() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("library.json")
        let repository: any LibraryRepository = FileLibraryRepository(documentURL: url)
        let entry = LibraryEntry(title: "Dune", format: .epub)
        try repository.upsert(entry)

        var revised = entry
        revised.title = "Dune (Revised)"
        revised.author = "Frank Herbert"
        try repository.upsert(revised)

        #expect(try repository.entries() == [revised])
    }

    @Test
    func missingDocumentStartsEmpty() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString).appendingPathComponent("library.json")
        let repository: any LibraryRepository = FileLibraryRepository(documentURL: url)
        #expect(try repository.entries().isEmpty)
    }

    @Test
    func successiveAdditionsPreserveAllEntries() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("library.json")
        let first: any LibraryRepository = FileLibraryRepository(documentURL: url)
        let second: any LibraryRepository = FileLibraryRepository(documentURL: url)
        let entries = LibraryEntry.TextFormat.allCases.map { format in
            LibraryEntry(title: "Book \(format.rawValue)", format: format)
        }
        try first.upsert(entries[0])
        try second.upsert(entries[1])
        try first.upsert(entries[2])
        #expect(try second.entries() == entries)
    }

    @Test
    func unreadableDocumentIsNotOverwrittenByUpsert() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("library.json")
        try Data("not a library document".utf8).write(to: url)
        let repository: any LibraryRepository = FileLibraryRepository(documentURL: url)
        #expect(throws: (any Error).self) { try repository.entries() }
        #expect(throws: (any Error).self) {
            try repository.upsert(LibraryEntry(title: "Dune", format: .epub))
        }
        #expect(throws: (any Error).self) { try repository.entries() }
    }

    @Test(.enabled(if: geteuid() != 0))
    func unwritableDestinationReportsFailure() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.setAttributes(
                [.posixPermissions: 0o700], ofItemAtPath: directory.path
            )
            try? FileManager.default.removeItem(at: directory)
        }
        let url = directory.appendingPathComponent("library.json")
        try Data("[]".utf8).write(to: url)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o500], ofItemAtPath: directory.path
        )
        let repository: any LibraryRepository = FileLibraryRepository(documentURL: url)
        #expect(throws: (any Error).self) {
            try repository.upsert(LibraryEntry(title: "Dune", format: .epub))
        }
        #expect(try repository.entries().isEmpty)
    }

    @Test
    func deletedEntryStaysGoneAfterReopeningRepository() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("library.json")
        let kept = LibraryEntry(title: "Dune", format: .epub)
        let removed = LibraryEntry(title: "Foundation", format: .pdf)
        let repository: any LibraryRepository = FileLibraryRepository(documentURL: url)
        try repository.upsert(kept)
        try repository.upsert(removed)

        try repository.delete(removed)

        let reopened: any LibraryRepository = FileLibraryRepository(documentURL: url)
        #expect(try reopened.entries() == [kept])
    }

    @Test
    func deletingAbsentEntryLeavesDocumentUnchanged() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("library.json")
        let entry = LibraryEntry(title: "Dune", format: .epub)
        let repository: any LibraryRepository = FileLibraryRepository(documentURL: url)
        try repository.upsert(entry)

        try repository.delete(LibraryEntry(title: "Foundation", format: .pdf))

        let reopened: any LibraryRepository = FileLibraryRepository(documentURL: url)
        #expect(try reopened.entries() == [entry])
    }

    @Test
    func deletingFromMissingDocumentCreatesNoDocument() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString).appendingPathComponent("library.json")
        let repository: any LibraryRepository = FileLibraryRepository(documentURL: url)

        try repository.delete(LibraryEntry(title: "Dune", format: .epub))

        #expect(!FileManager.default.fileExists(atPath: url.path))
    }

    @Test
    func persistedCoverImageIsRestored() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("library.json")
        let entry = LibraryEntry(
            title: "Dune",
            format: .epub,
            coverImageData: Data("thumbnail".utf8)
        )
        let repository: any LibraryRepository = FileLibraryRepository(documentURL: url)
        try repository.upsert(entry)

        let reopened: any LibraryRepository = FileLibraryRepository(documentURL: url)
        #expect(try reopened.entries() == [entry])
    }

    @Test
    func entryPersistedBeforeCoversExistedDecodesWithNoCover() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("library.json")
        let entry = LibraryEntry(title: "Dune", format: .epub, coverImageData: Data("old".utf8))
        var legacyEntries =
            try JSONSerialization.jsonObject(
                with: JSONEncoder().encode([entry])
            ) as? [[String: Any]]
        legacyEntries?[0].removeValue(forKey: "coverImageData")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try JSONSerialization.data(withJSONObject: legacyEntries as Any).write(to: url)

        let repository: any LibraryRepository = FileLibraryRepository(documentURL: url)

        #expect(try repository.entries().first?.coverImageData == nil)
    }
}
