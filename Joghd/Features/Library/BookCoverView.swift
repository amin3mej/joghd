import SwiftUI

struct BookCoverView: View {
    private static let backgroundSaturation: Double = 0.30
    private static let backgroundBrightness: Double = 0.82
    private static let foregroundSaturation: Double = 0.45
    private static let foregroundBrightness: Double = 0.28
    private static let contentSpacing: CGFloat = 6
    private static let contentPadding: CGFloat = 12
    private static let cornerRadius: CGFloat = 8
    private static let titleLineLimit = 5
    private static let authorLineLimit = 2
    private static let minimumScaleFactor: CGFloat = 0.5

    let cover: GeneratedCover

    var body: some View {
        ZStack {
            background
            VStack(spacing: Self.contentSpacing) {
                Text(cover.title)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .lineLimit(Self.titleLineLimit)
                    .minimumScaleFactor(Self.minimumScaleFactor)
                if let author = cover.author {
                    Text(author)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .lineLimit(Self.authorLineLimit)
                        .minimumScaleFactor(Self.minimumScaleFactor)
                }
            }
            .foregroundStyle(foreground)
            .padding(Self.contentPadding)
        }
        .aspectRatio(LibraryGridMetrics.coverAspectRatio, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius))
    }

    private var background: Color {
        Color(
            hue: cover.hue,
            saturation: Self.backgroundSaturation,
            brightness: Self.backgroundBrightness
        )
    }

    private var foreground: Color {
        Color(
            hue: cover.hue,
            saturation: Self.foregroundSaturation,
            brightness: Self.foregroundBrightness
        )
    }
}

#Preview {
    BookCoverView(cover: GeneratedCover(title: "Dune", author: "Frank Herbert"))
        .padding()
}
