import SwiftUI

struct ReaderView: View {
    let entry: LibraryEntry
    let fileStore: any BookFileStore
    let repository: any LibraryRepository
    @State private var store: ReaderStore?

    var body: some View {
        content
            .navigationTitle(entry.title)
            .navigationBarTitleDisplayMode(.inline)
            .alert("Couldn't save your place", isPresented: isShowingSaveError) {
                Button("OK", role: .cancel) {
                    store?.clearSaveError()
                }
            } message: {
                Text(store?.saveError ?? "")
            }
            .task {
                guard store == nil else {
                    return
                }
                let reader = ReaderStore(
                    entry: entry, fileStore: fileStore, repository: repository
                )
                store = reader
                await reader.load()
            }
    }

    private var isShowingSaveError: Binding<Bool> {
        Binding(
            get: { store?.saveError != nil },
            set: { isShowing in
                if !isShowing { store?.clearSaveError() }
            }
        )
    }

    @ViewBuilder
    private var content: some View {
        if let state = store?.state {
            switch state {
            case .loading:
                ProgressView()

            case .loaded(let document):
                BookPageView(document: document, initialLocation: store?.position) { location in
                    store?.record(location)
                }

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
