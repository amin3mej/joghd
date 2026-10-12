import SwiftUI

struct PaginationView: View {
    let document: BookDocument
    let initialLocation: Location?
    let pageSize: CGSize
    let onPositionChange: (Location) -> Void

    @State private var pages: [BookPage] = []
    @State private var currentPageID: Int?
    @State private var currentLocation: Location?

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(pages.indices, id: \.self) { index in
                    PageTextView(text: pages[index].text)
                        .frame(
                            width: max(pageSize.width, 0),
                            height: max(pageSize.height, 0),
                            alignment: .topLeading
                        )
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $currentPageID)
        .scrollIndicators(.hidden)
        .onChange(of: pageSize, initial: true) { _, size in
            paginate(size)
        }
        .onChange(of: document) { _, _ in
            paginate(pageSize)
        }
        .onChange(of: currentPageID) { _, index in
            reportPosition(at: index)
        }
    }

    private func paginate(_ size: CGSize) {
        let resumeLocation = currentLocation ?? initialLocation
        let newPages = BookPagination.pages(
            of: BookText.attributedString(of: document), pageSize: size
        )
        pages = newPages
        let index = resumeLocation.map { BookPagination.pageIndex(for: $0, in: newPages) } ?? 0
        currentLocation = resumeLocation
        currentPageID = index
    }

    private func reportPosition(at index: Int?) {
        guard let index, pages.indices.contains(index) else {
            return
        }
        let location = Location(containing: pages[index].range.location)
        currentLocation = location
        onPositionChange(location)
    }
}
