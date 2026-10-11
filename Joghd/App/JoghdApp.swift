import SwiftUI

@main
struct JoghdApp: App {
    @State private var library: LibraryStore
    @State private var isImporting = false
    @State private var importError: String?
    private let importService: ImportService

    var body: some Scene {
        WindowGroup {
            LibraryView(isImporting: $isImporting)
                .environment(library)
                .fileImporter(
                    isPresented: $isImporting,
                    allowedContentTypes: ImportFileTypes.allowed,
                    onCompletion: handleSelection
                )
                .alert("Import failed", isPresented: isShowingImportError) {
                    Button("OK", role: .cancel) {
                        importError = nil
                    }
                } message: {
                    Text(importError ?? "")
                }
        }
    }

    private var isShowingImportError: Binding<Bool> {
        Binding(
            get: { importError != nil },
            set: { isShowing in
                if !isShowing { importError = nil }
            }
        )
    }

    init() {
        _library = State(initialValue: LibraryStore(repository: FileLibraryRepository()))
        importService = ImportService(fileStore: FileBookFileStore())
    }

    private func handleSelection(_ result: Result<URL, any Error>) {
        switch result {
        case .success(let url):
            do {
                let entry = try importService.importFile(at: url)
                try library.add(entry)
                importError = nil
            } catch {
                importError = error.localizedDescription
            }

        case .failure(let error):
            if (error as? CocoaError)?.code != .userCancelled {
                importError = error.localizedDescription
            }
        }
    }
}
