import SwiftUI

@main
struct JoghdApp: App {
    @State private var library: LibraryStore
    @State private var isImporting = false
    @State private var draft: ImportDraft?
    @State private var pendingEntry: LibraryEntry?
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
                .sheet(item: $draft) { pending in
                    ImportConfirmationView(draft: pending, onConfirm: confirmImport)
                }
                .onOpenURL { handleSelection(.success($0)) }
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
            pendingEntry = nil
            do {
                draft = try importService.draft(for: url)
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

    private func confirmImport(_ draft: ImportDraft) -> String? {
        let entry: LibraryEntry
        do {
            if let pendingEntry {
                entry = importService.revise(pendingEntry, with: draft)
            } else {
                entry = try importService.confirm(draft)
            }
        } catch {
            return error.localizedDescription
        }

        do {
            try library.upsert(entry)
            pendingEntry = nil
            return nil
        } catch {
            pendingEntry = entry
            return error.localizedDescription
        }
    }
}
