import SwiftUI

/// Manual time block entry / edit with validation:
/// end must be after start, and break must be less than duration.
struct TimeBlockFormView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    /// nil for create; an existing block for edit.
    let block: TimeBlock?
    /// Optional preset job context (used from Job detail).
    var presetJobId: UUID? = nil

    enum EntryMode: String, CaseIterable, Identifiable {
        case startEnd
        case duration
        var id: String { rawValue }
        var key: LocalizedStringKey {
            self == .startEnd ? "tb.mode.startEnd" : "tb.mode.duration"
        }
    }

    @State private var mode: EntryMode = .startEnd
    @State private var date: Date = Date()
    @State private var startAt: Date = Date()
    @State private var endAt: Date = Date().addingTimeInterval(3600)
    @State private var durationMinutes: Int = 60
    @State private var breakMinutes: Int = 0
    @State private var selectedClientId: UUID?
    @State private var selectedJobId: UUID?
    @State private var rate: Double = 0
    @State private var billable: Bool = true
    @State private var notes: String = ""

    private var availableJobs: [Job] {
        guard let cid = selectedClientId else { return [] }
        return store.jobs(for: cid)
    }

    private var computedDuration: Int {
        switch mode {
        case .startEnd:
            return max(0, Int(endAt.timeIntervalSince(startAt) / 60.0))
        case .duration:
            return durationMinutes
        }
    }

    private var validationError: LocalizedStringKey? {
        if selectedClientId == nil { return "tb.error.client" }
        if selectedJobId == nil { return "tb.error.job" }
        if mode == .startEnd && endAt <= startAt { return "tb.error.endAfterStart" }
        if computedDuration <= 0 { return "tb.error.duration" }
        if breakMinutes >= computedDuration { return "tb.error.break" }
        return nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("tb.section.context") {
                    Picker("start.selectClient", selection: $selectedClientId) {
                        Text("start.none").tag(UUID?.none)
                        ForEach(store.activeClients()) { c in
                            Text(c.name).tag(UUID?.some(c.id))
                        }
                    }
                    .onChange(of: selectedClientId) { _ in selectedJobId = nil; applyRate() }
                    if selectedClientId != nil {
                        Picker("start.selectJob", selection: $selectedJobId) {
                            Text("start.none").tag(UUID?.none)
                            ForEach(availableJobs) { j in
                                Text(j.title).tag(UUID?.some(j.id))
                            }
                        }
                        .onChange(of: selectedJobId) { _ in applyRate() }
                    }
                }

                Section("tb.section.time") {
                    Picker("tb.mode", selection: $mode) {
                        ForEach(EntryMode.allCases) { m in
                            Text(m.key).tag(m)
                        }
                    }
                    .pickerStyle(.segmented)

                    if mode == .startEnd {
                        DatePicker("tb.start", selection: $startAt)
                        DatePicker("tb.end", selection: $endAt)
                    } else {
                        DatePicker("tb.date", selection: $date, displayedComponents: .date)
                        Stepper(value: $durationMinutes, in: 0...1440, step: 5) {
                            Text("tb.durationValue \(Formatters.hoursMinutes(durationMinutes))")
                        }
                    }
                    Stepper(value: $breakMinutes, in: 0...600, step: 5) {
                        Text("tb.breakValue \(breakMinutes)")
                    }
                }

                Section("tb.section.billing") {
                    HStack {
                        Text("field.rate")
                        Spacer()
                        TextField("field.rate", value: $rate, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    Toggle("field.billable", isOn: $billable)
                }

                Section("field.notes") {
                    TextField("field.notes", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }

                if let err = validationError {
                    Section {
                        Label(err, systemImage: "exclamationmark.triangle")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle(block == nil ? "tb.titleNew" : "tb.titleEdit")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save") { save() }
                        .disabled(validationError != nil)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        if let b = block {
            selectedClientId = b.clientId
            selectedJobId = b.jobId
            breakMinutes = b.breakMinutes
            rate = b.rate
            billable = b.billable
            if let s = b.startAt, let e = b.endAt {
                mode = .startEnd
                startAt = s
                endAt = e
            } else {
                mode = .duration
                durationMinutes = b.durationMinutes
                date = b.startAt ?? Date()
            }
        } else {
            if let pj = presetJobId, let job = store.job(pj) {
                selectedClientId = job.clientId
                selectedJobId = job.id
            } else {
                selectedClientId = store.activeClients().first?.id
            }
            applyRate()
        }
    }

    private func applyRate() {
        if let jid = selectedJobId, let job = store.job(jid), let r = job.defaultRate {
            rate = r
        } else if let cid = selectedClientId, let c = store.client(cid), c.defaultRate > 0 {
            rate = c.defaultRate
        } else if rate == 0 {
            rate = store.settings.defaultRate
        }
    }

    private func save() {
        guard let cid = selectedClientId, let jid = selectedJobId else { return }
        var result = block ?? TimeBlock(clientId: cid, jobId: jid,
                                        startAt: nil, endAt: nil,
                                        durationMinutes: 0, breakMinutes: 0,
                                        billable: billable, rate: rate)
        result.clientId = cid
        result.jobId = jid
        result.breakMinutes = breakMinutes
        result.rate = rate
        result.billable = billable

        switch mode {
        case .startEnd:
            result.startAt = startAt
            result.endAt = endAt
            result.durationMinutes = max(0, Int(endAt.timeIntervalSince(startAt) / 60.0))
        case .duration:
            let start = Calendar.current.startOfDay(for: date).addingTimeInterval(9 * 3600)
            result.startAt = start
            result.endAt = start.addingTimeInterval(Double(durationMinutes) * 60)
            result.durationMinutes = durationMinutes
        }
        store.upsert(result)
        dismiss()
    }
}
