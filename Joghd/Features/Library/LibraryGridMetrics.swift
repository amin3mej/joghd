import SwiftUI

enum LibraryGridMetrics {
    static let spacing: CGFloat = 16
    static let coverAspectRatio: CGFloat = coverWidth / coverHeight
    static let columns = Array(
        repeating: GridItem(.flexible(), spacing: spacing, alignment: .top),
        count: columnCount
    )

    private static let columnCount = 2
    private static let coverWidth: CGFloat = 2
    private static let coverHeight: CGFloat = 3
}
