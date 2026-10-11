import Foundation
import Testing

@testable import Joghd

@MainActor
struct LibraryRepositoryTests {
    @Test
    func addedEntrySurvivesReopeningRepository() throws {
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
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("library.json")
        let first: any LibraryRepository = FileLibraryRepository(documentURL: url)
        let second: any LibraryRepository = FileLibraryRepository(documentURL: url)
        let entries = LibraryEntry.TextFormat.allCases.map { format in
            LibraryEntry(title: "Book \(format.rawValue)", format: format)
        }
        try first.add(entries[0])
        try second.add(entries[1])
        try first.add(entries[2])
        #expect(try second.entries() == entries)
    }

    @Test
    func unreadableDocumentIsNotOverwrittenByAddition() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("library.json")
        try Data("not a library document".utf8).write(to: url)
        let repository: any LibraryRepository = FileLibraryRepository(documentURL: url)
        #expect(throws: (any Error).self) { try repository.entries() }
        #expect(throws: (any Error).self) {
            try repository.add(LibraryEntry(title: "Dune", format: .epub))
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
            try repository.add(LibraryEntry(title: "Dune", format: .epub))
        }
        #expect(try repository.entries().isEmpty)
    }
}
