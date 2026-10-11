import SwiftUI

struct ImportConfirmationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: ImportDraft
    @State private var errorMessage: String?
    let onConfirm: (ImportDraft) -> String?

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
                        if let message = onConfirm(draft) {
                            errorMessage = message
                        } else {
                            dismiss()
                        }
                    }
                }
            }
            .alert("Import failed", isPresented: isShowingError) {
                Button("OK", role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private var isShowingError: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { isShowing in
                if !isShowing { errorMessage = nil }
            }
        )
    }

    init(draft: ImportDraft, onConfirm: @escaping (ImportDraft) -> String?) {
        _draft = State(initialValue: draft)
        self.onConfirm = onConfirm
    }
}
