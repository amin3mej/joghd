import SwiftUI

struct LibrarySearchBar: View {
    private static let verticalSpacing: CGFloat = 8
    private static let cornerRadius: CGFloat = 24
    private static let fieldSpacing: CGFloat = 8
    private static let clearButtonSize: CGFloat = 44
    private static let horizontalPadding: CGFloat = 16
    private static let fieldPadding: CGFloat = 4
    private static let minimumHeight: CGFloat = 52

    @Binding var query: String
    @FocusState private var isFocused: Bool

    var body: some View {
        platformSearchField
            .padding(.horizontal)
            .padding(.vertical, Self.verticalSpacing)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isFocused = false
                    }
                }
            }
    }

    @ViewBuilder
    private var platformSearchField: some View {
        if #available(iOS 26, *) {
            searchField.glassEffect(.regular.interactive(), in: .rect(cornerRadius: Self.cornerRadius))
        } else {
            searchField.background(.regularMaterial, in: RoundedRectangle(cornerRadius: Self.cornerRadius))
        }
    }

    private var searchField: some View {
        HStack(spacing: Self.fieldSpacing) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            TextField("Search title or author", text: $query)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .focused($isFocused)
                .onSubmit { isFocused = false }
                .accessibilityLabel("Search library")
                .accessibilityHint("Filters books by title or author")
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .frame(minWidth: Self.clearButtonSize, minHeight: Self.clearButtonSize)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.leading, Self.horizontalPadding)
        .padding(.trailing, query.isEmpty ? Self.horizontalPadding : Self.fieldPadding)
        .padding(.vertical, Self.fieldPadding)
        .frame(minHeight: Self.minimumHeight)
    }
}
