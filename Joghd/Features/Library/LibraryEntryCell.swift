import SwiftUI
import UIKit

struct LibraryEntryCell: View {
    private static let coverToTextSpacing: CGFloat = 8
    private static let textSpacing: CGFloat = 2
    private static let titleLineLimit = 2
    private static let authorLineLimit = 1

    let entry: LibraryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: Self.coverToTextSpacing) {
            cover
            VStack(alignment: .leading, spacing: Self.textSpacing) {
                Text(entry.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(Self.titleLineLimit)
                if let author = entry.author {
                    Text(author)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(Self.authorLineLimit)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(entry.coverAccessibilityLabel)
    }

    @ViewBuilder
    private var cover: some View {
        if let data = entry.coverImageData, let image = UIImage(data: data) {
            CoverImageView(image: image)
        } else {
            BookCoverView(cover: GeneratedCover(title: entry.title, author: entry.author))
        }
    }
}

extension LibraryEntry {
    var coverAccessibilityLabel: String {
        guard let author else {
            return title
        }
        return "\(title), by \(author)"
    }
}

#Preview {
    LibraryEntryCell(entry: LibraryEntry(title: "Dune", author: "Frank Herbert", format: .epub))
        .frame(width: 180)
        .padding()
}
