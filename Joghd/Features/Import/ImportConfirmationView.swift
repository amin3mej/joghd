import SwiftUI

struct ImportConfirmationView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var draft: ImportDraft
    let onConfirm: (ImportDraft) -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $draft.title)
                TextField("Author", text: $draft.author)
            }
            .navigationTitle("Add Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onConfirm(draft)
                        dismiss()
                    }
                }
            }
        }
    }
}
