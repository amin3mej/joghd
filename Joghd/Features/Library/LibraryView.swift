import SwiftUI

struct LibraryView: View {
    @Environment(LibraryStore.self) private var library
    @Environment(\.scenePhase) private var scenePhase
    @Binding var isImporting: Bool
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
                    grid
                }
            }
            .navigationTitle("Library")
            .onChange(of: scenePhase, initial: true) { _, phase in
                if phase == .active { reload() }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Import", systemImage: "plus") {
                        isImporting = true
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No books yet", systemImage: "books.vertical")
        } description: {
            Text("Import an EPUB or Markdown file to start reading.")
        }
    }

    private var grid: some View {
        LibraryGridView(entries: library.entries)
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
    LibraryView(isImporting: .constant(false))
        .environment(LibraryStore(repository: PreviewLibraryRepository()))
}
