import SwiftUI

struct CoverImageView: View {
    let image: UIImage

    var body: some View {
        ZStack {
            Color(.secondarySystemBackground)
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .accessibilityHidden(true)
        }
        .aspectRatio(LibraryGridMetrics.coverAspectRatio, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: LibraryGridMetrics.coverCornerRadius))
    }
}
