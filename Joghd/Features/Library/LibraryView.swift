// SPDX-License-Identifier: MPL-2.0
import SwiftUI

/// The reader's home screen: the on-device book library.
struct LibraryView: View {
    @Environment(LibraryStore.self) private var library

    var body: some View {
        NavigationStack {
            Group {
                if library.entries.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("Library")
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
}

#Preview {
    LibraryView()
        .environment(LibraryStore())
}
