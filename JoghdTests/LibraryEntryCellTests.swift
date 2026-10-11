import Testing

@testable import Joghd

struct LibraryEntryCellTests {
    @Test
    func accessibilityLabelNamesTheAuthorWhenPresent() {
        let entry = LibraryEntry(title: "Dune", author: "Frank Herbert", format: .epub)
        #expect(entry.coverAccessibilityLabel == "Dune, by Frank Herbert")
    }

    @Test
    func accessibilityLabelIsTitleOnlyWithoutAnAuthor() {
        let entry = LibraryEntry(title: "Dune", format: .epub)
        #expect(entry.coverAccessibilityLabel == "Dune")
    }
}
