import SwiftUI

@main
struct JoghdApp: App {
    @State private var library = LibraryStore(repository: FileLibraryRepository())

    var body: some Scene {
        WindowGroup {
            LibraryView()
                .environment(library)
        }
    }
}
