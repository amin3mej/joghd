import SwiftUI

struct BookPageView: View {
    private enum PageInsets {
        static let horizontal: CGFloat = 24
        static let vertical: CGFloat = 32
    }

    let document: BookDocument
    let initialLocation: Location?
    let onPositionChange: (Location) -> Void

    var body: some View {
        GeometryReader { proxy in
            let pageSize = CGRect(origin: .zero, size: proxy.size)
                .insetBy(dx: PageInsets.horizontal, dy: PageInsets.vertical)
                .size
            PaginationView(
                document: document,
                initialLocation: initialLocation,
                pageSize: pageSize,
                onPositionChange: onPositionChange
            )
            .padding(.horizontal, PageInsets.horizontal)
            .padding(.vertical, PageInsets.vertical)
        }
    }
}
