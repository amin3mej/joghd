import SwiftUI

struct PaginationView: View {
    let document: BookDocument
    let pageSize: CGSize
    @State private var pages: [NSAttributedString] = []

    var body: some View {
        PageTextView(text: pages.first ?? NSAttributedString())
            .frame(
                width: max(pageSize.width, 0),
                height: max(pageSize.height, 0),
                alignment: .topLeading
            )
            .onChange(of: pageSize, initial: true) { _, size in
                paginate(size)
            }
            .onChange(of: document) { _, _ in
                paginate(pageSize)
            }
    }

    private func paginate(_ size: CGSize) {
        pages = BookPagination.pages(
            of: BookText.attributedString(of: document), pageSize: size
        )
    }
}
