import SwiftUI

struct LibraryGridView: View {
    let entries: [LibraryEntry]

    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: LibraryGridMetrics.columns,
                spacing: LibraryGridMetrics.spacing
            ) {
                ForEach(entries) { entry in
                    LibraryEntryCell(entry: entry)
                }
            }
            .padding()
        }
    }
}

#Preview {
    LibraryGridView(
        entries: [LibraryEntry(title: "Dune", author: "Frank Herbert", format: .epub)]
    )
}
