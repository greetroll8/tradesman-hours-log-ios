import SwiftUI

/// Simple work note entry attached to a job (and optionally a time block).
struct NoteFormView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let jobId: UUID
    let timeBlockId: UUID?

    @State private var text: String = ""

    private var canSave: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("note.section.text") {
                    TextField("note.placeholder", text: $text, axis: .vertical)
                        .lineLimit(3...8)
                }
            }
            .navigationTitle("note.title")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save") {
                        store.add(WorkNote(jobId: jobId,
                                           timeBlockId: timeBlockId,
                                           text: text.trimmingCharacters(in: .whitespacesAndNewlines),
                                           createdAt: Date()))
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
}
