import SwiftUI

/// Detailed active-timer view: elapsed, stop, break toggle, add material/note/photo.
struct ActiveTimerDetailView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var timer: TimerController
    @Environment(\.dismiss) private var dismiss
    let blockId: UUID

    @State private var showMaterial = false
    @State private var showNote = false
    @State private var showPhoto = false

    private var block: TimeBlock? { store.timeBlocks.first { $0.id == blockId } }

    var body: some View {
        Group {
            if let block, block.isRunning {
                content(block)
            } else {
                EmptyStateView(titleKey: "active.stopped", systemImage: "checkmark.circle")
            }
        }
        .navigationTitle("active.title")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func content(_ block: TimeBlock) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                ActiveTimerCard(block: block)

                Toggle(isOn: Binding(
                    get: { block.breakMinutes > 0 },
                    set: { on in toggleBreak(on, block) }
                )) {
                    Label("active.onBreak", systemImage: "pause.circle")
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                HStack(spacing: 10) {
                    QuickChip(titleKey: "chip.material", systemImage: "shippingbox") { showMaterial = true }
                    QuickChip(titleKey: "chip.note", systemImage: "note.text") { showNote = true }
                    QuickChip(titleKey: "chip.photo", systemImage: "camera") { showPhoto = true }
                }

                attachedItems(block)
            }
            .padding()
        }
        .sheet(isPresented: $showMaterial) {
            MaterialFormView(jobId: block.jobId, timeBlockId: block.id, material: nil)
        }
        .sheet(isPresented: $showNote) {
            NoteFormView(jobId: block.jobId, timeBlockId: block.id)
        }
        .sheet(isPresented: $showPhoto) {
            PhotoPicker { path in
                store.add(Photo(jobId: block.jobId, timeBlockId: block.id,
                                localPath: path, caption: nil))
            }
        }
    }

    @ViewBuilder
    private func attachedItems(_ block: TimeBlock) -> some View {
        let mats = store.materials.filter { $0.timeBlockId == block.id }
        let notes = store.notes.filter { $0.timeBlockId == block.id }
        if !mats.isEmpty || !notes.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                if !mats.isEmpty {
                    Text("active.materials").font(.headline)
                    ForEach(mats) { m in
                        HStack {
                            Text(m.name)
                            Spacer()
                            AmountText(amount: m.lineTotal, currency: store.settings.currency)
                        }
                        .font(.subheadline)
                    }
                }
                if !notes.isEmpty {
                    Text("active.notes").font(.headline)
                    ForEach(notes) { n in
                        Text(n.text).font(.subheadline)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func toggleBreak(_ on: Bool, _ block: TimeBlock) {
        var b = block
        b.breakMinutes = on ? max(5, b.breakMinutes) : 0
        store.upsert(b)
    }
}
