import Foundation
import Testing
import UniformTypeIdentifiers

@testable import Joghd

struct AppDocumentTypesTests {
    @Test
    func declaresEveryFormatThePickerAccepts() {
        let declared = Set(declaredContentTypes())
        for identifier in ImportFileTypes.allowed.map(\.identifier) {
            #expect(declared.contains(identifier))
        }
    }

    @Test
    func declaresImportedMarkdownType() {
        #expect(importedTypeIdentifiers().contains(ImportFileTypes.markdown.identifier))
    }

    @Test
    func acceptsIncomingFilesInPlace() {
        let key = "LSSupportsOpeningDocumentsInPlace"
        let inPlace = Bundle.main.object(forInfoDictionaryKey: key) as? Bool
        #expect(inPlace == true)
    }
}

private func declaredContentTypes() -> [String] {
    infoArray(forKey: "CFBundleDocumentTypes").flatMap { entry in
        entry["LSItemContentTypes"] as? [String] ?? []
    }
}

private func importedTypeIdentifiers() -> [String] {
    infoArray(forKey: "UTImportedTypeDeclarations").compactMap { entry in
        entry["UTTypeIdentifier"] as? String
    }
}

private func infoArray(forKey key: String) -> [[String: Any]] {
    Bundle.main.object(forInfoDictionaryKey: key) as? [[String: Any]] ?? []
}
