import SwiftUI

struct ImportConfirmationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: ImportDraft
    @State private var errorMessage: String?
    @State private var isConfirming = false
    let onConfirm: (ImportDraft) async -> String?

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $draft.title)
                TextField("Author", text: $draft.author)
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
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
                    Button("Add", action: confirm)
                }
            }
            .disabled(isConfirming)
            .interactiveDismissDisabled(isConfirming)
            .overlay {
                if isConfirming {
                    ProgressView("Opening…")
                }
            }
        }
    }

    init(draft: ImportDraft, onConfirm: @escaping (ImportDraft) async -> String?) {
        _draft = State(initialValue: draft)
        self.onConfirm = onConfirm
    }

    private func confirm() {
        isConfirming = true
        Task {
            defer { isConfirming = false }
            if let message = await onConfirm(draft) {
                errorMessage = message
            } else {
                dismiss()
            }
        }
    }
}
