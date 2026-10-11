import SwiftUI

struct LibraryEntryCell: View {
    private static let coverToTextSpacing: CGFloat = 8
    private static let textSpacing: CGFloat = 2
    private static let titleLineLimit = 2
    private static let authorLineLimit = 1

    let entry: LibraryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: Self.coverToTextSpacing) {
            BookCoverView(cover: GeneratedCover(title: entry.title, author: entry.author))
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
