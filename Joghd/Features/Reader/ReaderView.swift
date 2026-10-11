import SwiftUI

struct ReaderView: View {
    let entry: LibraryEntry
    let fileStore: any BookFileStore
    @State private var store: ReaderStore?

    var body: some View {
        content
            .navigationTitle(entry.title)
            .navigationBarTitleDisplayMode(.inline)
            .task {
                guard store == nil else {
                    return
                }
                let reader = ReaderStore(entry: entry, fileStore: fileStore)
                store = reader
                await reader.load()
            }
    }

    @ViewBuilder
    private var content: some View {
        if let state = store?.state {
            switch state {
            case .loading:
                ProgressView()

            case .loaded(let document):
                BookPageView(document: document)

            case .failed(let message):
                ContentUnavailableView {
                    Label("Can't open this book", systemImage: "book.closed")
                } description: {
                    Text(message)
                }
            }
        } else {
            ProgressView()
        }
    }
}
