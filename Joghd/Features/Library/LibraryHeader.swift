import SwiftUI

struct LibraryHeader: View {
    private static let horizontalSpacing: CGFloat = 12
    private static let verticalSpacing: CGFloat = 8

    let onImport: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            horizontal
            vertical
        }
        .padding(.horizontal)
        .padding(.vertical, Self.verticalSpacing)
        .background(.bar)
    }

    private var horizontal: some View {
        HStack(alignment: .firstTextBaseline, spacing: Self.horizontalSpacing) {
            heading
            Spacer(minLength: 0)
            platformImportButton
        }
    }

    private var vertical: some View {
        VStack(alignment: .leading, spacing: Self.verticalSpacing) {
            heading
            platformImportButton
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var heading: some View {
        Text("Library")
            .font(.largeTitle.bold())
            .fixedSize(horizontal: true, vertical: false)
            .accessibilityAddTraits(.isHeader)
    }

    @ViewBuilder
    private var platformImportButton: some View {
        if #available(iOS 26, *) {
            importButton.buttonStyle(.glass)
        } else {
            importButton.buttonStyle(.borderedProminent)
        }
    }

    private var importButton: some View {
        Button(action: onImport) {
            Label("Import", systemImage: "plus")
                .labelStyle(.iconOnly)
        }
        .controlSize(.large)
        .fixedSize(horizontal: true, vertical: false)
    }
}

#Preview {
    LibraryHeader { () }
}
