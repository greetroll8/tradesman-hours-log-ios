import SwiftUI

/// Job detail: totals, a timeline of time blocks and notes, and actions.
struct JobDetailView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    let jobId: UUID

    @State private var showEdit = false
    @State private var showAddBlock = false
    @State private var showAddMaterial = false
    @State private var showAddNote = false

    private var job: Job? { store.job(jobId) }

    private var blocks: [TimeBlock] {
        store.timeBlocks(for: jobId).sorted {
            ($0.startAt ?? .distantPast) > ($1.startAt ?? .distantPast)
        }
    }

    private var totalMinutes: Int { blocks.reduce(0) { $0 + $1.netMinutes } }
    private var laborTotal: Double {
        blocks.reduce(0) { acc, b in
            acc + (b.billable ? Double(b.netMinutes) / 60.0 * b.rate : 0)
        }
    }
    private var materialsTotal: Double {
        store.materials(for: jobId).reduce(0) { $0 + ($1.billable ? $1.lineTotal : 0) }
    }

    var body: some View {
        Group {
            if let job {
                content(job)
            } else {
                EmptyStateView(titleKey: "job.deleted", systemImage: "trash")
            }
        }
        .navigationTitle(job?.title ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showEdit = true } label: { Label("common.edit", systemImage: "pencil") }
                    Button { showAddBlock = true } label: { Label("job.addBlock", systemImage: "clock") }
                    Button { showAddMaterial = true } label: { Label("chip.material", systemImage: "shippingbox") }
                    Button { showAddNote = true } label: { Label("chip.note", systemImage: "note.text") }
                    if let job {
                        Button(role: .destructive) {
                            store.deleteJob(job.id)
                            dismiss()
                        } label: { Label("common.delete", systemImage: "trash") }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            if let job { JobFormView(job: job) }
        }
        .sheet(isPresented: $showAddBlock) {
            TimeBlockFormView(block: nil, presetJobId: jobId)
        }
        .sheet(isPresented: $showAddMaterial) {
            MaterialFormView(jobId: jobId, timeBlockId: nil, material: nil)
        }
        .sheet(isPresented: $showAddNote) {
            NoteFormView(jobId: jobId, timeBlockId: nil)
        }
    }

    @ViewBuilder
    private func content(_ job: Job) -> some View {
        List {
            Section("job.section.totals") {
                LabeledContent("job.totalHours", value: Formatters.hoursMinutes(totalMinutes))
                LabeledContent("report.subtotal.labor") {
                    AmountText(amount: laborTotal, currency: store.settings.currency)
                }
                LabeledContent("report.subtotal.materials") {
                    AmountText(amount: materialsTotal, currency: store.settings.currency)
                }
                LabeledContent("report.total") {
                    AmountText(amount: laborTotal + materialsTotal, currency: store.settings.currency)
                        .fontWeight(.semibold)
                }
            }

            Section("job.section.timeline") {
                if blocks.isEmpty {
                    Text("job.noBlocks").foregroundColor(.secondary)
                }
                ForEach(blocks) { block in
                    TimelineBlockRow(block: block)
                }
                .onDelete { offsets in
                    for i in offsets { store.deleteTimeBlock(blocks[i].id) }
                }
            }

            let notes = store.notes(for: jobId)
            if !notes.isEmpty {
                Section("active.notes") {
                    ForEach(notes) { n in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(n.text)
                            Text(n.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .onDelete { offsets in
                        for i in offsets { store.deleteNote(notes[i].id) }
                    }
                }
            }

            let mats = store.materials(for: jobId)
            if !mats.isEmpty {
                Section("active.materials") {
                    ForEach(mats) { m in
                        HStack {
                            Text(m.name)
                            Spacer()
                            AmountText(amount: m.lineTotal, currency: store.settings.currency)
                        }
                    }
                    .onDelete { offsets in
                        for i in offsets { store.deleteMaterial(mats[i].id) }
                    }
                }
            }
        }
    }
}

struct TimelineBlockRow: View {
    @EnvironmentObject var store: AppStore
    let block: TimeBlock

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                if let s = block.startAt {
                    Text(s.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline)
                }
                HStack(spacing: 6) {
                    Text(Formatters.hoursMinutes(block.netMinutes))
                        .monospacedDigit()
                    if !block.billable {
                        Text("report.nonbillable")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            Spacer()
            AmountText(amount: block.billable ? Double(block.netMinutes) / 60.0 * block.rate : 0,
                       currency: store.settings.currency)
                .font(.subheadline)
        }
    }
}
