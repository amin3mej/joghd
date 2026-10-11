import Foundation
import Testing

@testable import Joghd

@MainActor
struct LibraryRepositoryTests {
    @Test
    func addedEntrySurvivesReopeningRepository() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("library.json")
        let entry = LibraryEntry(
            title: "Dune", author: "Frank Herbert", format: .epub,
            importedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let repository: any LibraryRepository = FileLibraryRepository(documentURL: url)
        try repository.add(entry)

        let reopened: any LibraryRepository = FileLibraryRepository(documentURL: url)
        #expect(try reopened.entries() == [entry])
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
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("library.json")
        let first: any LibraryRepository = FileLibraryRepository(documentURL: url)
        let second: any LibraryRepository = FileLibraryRepository(documentURL: url)
        let entries = LibraryEntry.TextFormat.allCases.map {
            LibraryEntry(title: "Book \($0.rawValue)", format: $0)
        }
        try first.add(entries[0])
        try second.add(entries[1])
        try first.add(entries[2])
        #expect(try second.entries() == entries)
    }

    @Test
    func unreadableDocumentIsNotOverwrittenByAddition() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("library.json")
        // Simulate an existing damaged document at the storage boundary.
        try Data("not a library document".utf8).write(to: url)
        let repository: any LibraryRepository = FileLibraryRepository(documentURL: url)
        #expect(throws: (any Error).self) { try repository.entries() }
        #expect(throws: (any Error).self) {
            try repository.add(LibraryEntry(title: "Dune", format: .epub))
        }
        #expect(throws: (any Error).self) { try repository.entries() }
    }

    @Test
    func unwritableDestinationReportsFailure() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let repository: any LibraryRepository = FileLibraryRepository(documentURL: directory)
        #expect(throws: (any Error).self) {
            try repository.add(LibraryEntry(title: "Dune", format: .epub))
        }
    }
}
