import SwiftUI

struct LibraryView: View {
    @Environment(LibraryStore.self) private var library
    @Environment(\.scenePhase) private var scenePhase
    @Binding var isImporting: Bool
    @State private var loadError: String?
    @State private var entryPendingDeletion: LibraryEntry?
    @State private var deleteError: String?

    var body: some View {
        @Bindable var library = library

        deleteAlerts(libraryContent)
            .safeAreaInset(edge: .top, spacing: 0) {
                LibraryHeader {
                    isImporting = true
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                LibrarySearchBar(query: $library.searchQuery)
            }
            .toolbar(.hidden, for: .navigationBar)
            .onChange(of: scenePhase, initial: true) { _, phase in
                if phase == .active { reload() }
            }
    }

    @ViewBuilder
    private var libraryContent: some View {
        if let loadError {
            ContentUnavailableView {
                Label("Library unavailable", systemImage: "exclamationmark.triangle")
            } description: {
                Text(loadError)
            } actions: {
                Button("Retry", action: reload)
            }
        } else if library.entries.isEmpty {
            emptyState
        } else if library.filteredEntries.isEmpty {
            ContentUnavailableView {
                Label("No matching books", systemImage: "magnifyingglass")
            } description: {
                Text("Try a different title or author, or clear your search.")
            }
        } else {
            grid
        }
    }

    private var isConfirmingDeletion: Binding<Bool> {
        Binding(
            get: { entryPendingDeletion != nil },
            set: { isConfirming in
                if !isConfirming { entryPendingDeletion = nil }
            }
        )
    }

    private var isShowingDeleteError: Binding<Bool> {
        Binding(
            get: { deleteError != nil },
            set: { isShowing in
                if !isShowing { deleteError = nil }
            }
        )
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No books yet", systemImage: "books.vertical")
        } description: {
            Text("Import an EPUB or Markdown file to start reading.")
        }
    }

    private var grid: some View {
        LibraryGridView(entries: library.filteredEntries) { entry in
            entryPendingDeletion = entry
        }
    }

    private func deleteAlerts<Content: View>(_ content: Content) -> some View {
        content
            .confirmationDialog(
                "Delete this book?",
                isPresented: isConfirmingDeletion,
                presenting: entryPendingDeletion
            ) { entry in
                Button("Delete", role: .destructive) {
                    delete(entry)
                }
            } message: { entry in
                Text("\"\(entry.title)\" and its file will be removed.")
            }
            .alert("Couldn't delete", isPresented: isShowingDeleteError) {
                Button("OK", role: .cancel) {
                    deleteError = nil
                }
            } message: {
                Text(deleteError ?? "")
            }
    }

    private func reload() {
        do {
            try library.reload()
            loadError = nil
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func delete(_ entry: LibraryEntry) {
        do {
            try library.delete(entry)
            deleteError = nil
        } catch {
            deleteError = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        LibraryView(isImporting: .constant(false))
    }
    .environment(
        LibraryStore(
            repository: PreviewLibraryRepository(),
            fileStore: PreviewBookFileStore()
        )
    )
}
