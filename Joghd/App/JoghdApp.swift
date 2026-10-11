// SPDX-License-Identifier: MPL-2.0
import SwiftUI

@main
struct JoghdApp: App {
    @State private var library = LibraryStore()

    var body: some Scene {
        WindowGroup {
            LibraryView()
                .environment(library)
        }
    }
}
