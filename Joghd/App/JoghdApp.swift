import SwiftUI

@main
struct JoghdApp: App {
    @State private var library: LibraryStore
    @State private var isImporting = false
    @State private var draft: ImportDraft?
    @State private var pendingEntry: LibraryEntry?
    @State private var importActivity = ImportActivity()
    @State private var importError: String?
    @State private var currentSelectionID = UUID()
    private let importService: ImportService
    private let fileStore: any BookFileStore

    var body: some Scene {
        WindowGroup {
            rootView
        }
    }

    private var rootView: some View {
        NavigationStack {
            LibraryView(isImporting: $isImporting)
                .navigationDestination(for: LibraryEntry.self) { entry in
                    ReaderView(entry: entry, fileStore: fileStore)
                }
        }
        .environment(library)
        .overlay {
            if importActivity.isActive {
                ProgressView("Opening…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.regularMaterial)
                    .ignoresSafeArea()
            }
        }
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

    private var isShowingImportError: Binding<Bool> {
        Binding(
            get: { importError != nil },
            set: { isShowing in
                if !isShowing { importError = nil }
            }
        )
    }

    init() {
        let store = FileBookFileStore()
        self.fileStore = store
        _library = State(
            initialValue: LibraryStore(
                repository: FileLibraryRepository(),
                fileStore: store
            )
        )
        importService = ImportService(fileStore: store)
    }

    private func handleSelection(_ result: Result<URL, any Error>) {
        switch result {
        case .success(let url):
            pendingEntry = nil
            let selectionID = UUID()
            currentSelectionID = selectionID
            Task {
                do {
                    let newDraft = try await importService.draft(for: url)
                    guard currentSelectionID == selectionID else {
                        return
                    }
                    draft = newDraft
                    importError = nil
                } catch {
                    guard currentSelectionID == selectionID else {
                        return
                    }
                    importError = error.localizedDescription
                }
            }

        case .failure(let error):
            if (error as? CocoaError)?.code != .userCancelled {
                importError = error.localizedDescription
            }
        }
    }

    private func confirmImport(_ draft: ImportDraft) async -> String? {
        importActivity.begin()
        defer { importActivity.end() }
        let entry: LibraryEntry
        do {
            if let pendingEntry {
                entry = importService.revise(pendingEntry, with: draft)
            } else {
                entry = try await importService.confirm(draft)
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
