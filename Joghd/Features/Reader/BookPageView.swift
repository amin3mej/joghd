import SwiftUI

struct BookPageView: View {
    private enum PageInsets {
        static let horizontal: CGFloat = 24
        static let vertical: CGFloat = 32
    }

    let document: BookDocument

    var body: some View {
        GeometryReader { proxy in
            let pageSize = CGRect(origin: .zero, size: proxy.size)
                .insetBy(dx: PageInsets.horizontal, dy: PageInsets.vertical)
                .size
            PaginationView(document: document, pageSize: pageSize)
                .padding(.horizontal, PageInsets.horizontal)
                .padding(.vertical, PageInsets.vertical)
        }
    }
}
