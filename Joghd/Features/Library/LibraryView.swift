import SwiftUI

/// The reader's home screen: the on-device book library.
struct LibraryView: View {
    @Environment(LibraryStore.self) private var library
    @Environment(\.scenePhase) private var scenePhase
    @State private var loadError: String?

    var body: some View {
        NavigationStack {
            Group {
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
                } else {
                    list
                }
            }
            .navigationTitle("Library")
            .task { reload() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { reload() }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Import", systemImage: "plus") {
                        // V1: import EPUB, Markdown, or PDF from Files or the share sheet.
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No books yet", systemImage: "books.vertical")
        } description: {
            Text("Import an EPUB, Markdown, or PDF file to start reading.")
        }
    }

    private var list: some View {
        List(library.entries) { entry in
            Text(entry.title)
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
}

#Preview {
    LibraryView()
        .environment(LibraryStore(repository: PreviewLibraryRepository()))
}
