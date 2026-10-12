import SwiftUI

struct LibraryGridView: View {
    let entries: [LibraryEntry]
    let onDelete: (LibraryEntry) -> Void

    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: LibraryGridMetrics.columns,
                spacing: LibraryGridMetrics.spacing
            ) {
                ForEach(entries) { entry in
                    NavigationLink(value: entry) {
                        LibraryEntryCell(entry: entry)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Delete", role: .destructive) {
                            onDelete(entry)
                        }
                    }
                }
            }
            .padding()
        }
    }
}

#Preview {
    NavigationStack {
        LibraryGridView(
            entries: [LibraryEntry(title: "Dune", author: "Frank Herbert", format: .epub)]
        ) { _ in () }
    }
}
