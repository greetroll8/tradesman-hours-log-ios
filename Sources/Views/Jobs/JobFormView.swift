import SwiftUI

/// Job create / edit. Title and client required.
struct JobFormView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let job: Job?
    var presetClientId: UUID? = nil

    @State private var title: String = ""
    @State private var clientId: UUID?
    @State private var status: JobStatus = .active
    @State private var useCustomRate: Bool = false
    @State private var rate: Double = 0
    @State private var notes: String = ""
    @State private var loaded = false

    private var canSave: Bool {
        clientId != nil && !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("job.section.basics") {
                    TextField("field.title", text: $title)
                    Picker("start.selectClient", selection: $clientId) {
                        Text("start.none").tag(UUID?.none)
                        ForEach(store.activeClients()) { c in
                            Text(c.name).tag(UUID?.some(c.id))
                        }
                    }
                    Picker("field.status", selection: $status) {
                        ForEach(JobStatus.allCases) { s in
                            Text(LocalizedStringKey(s.localizationKey)).tag(s)
                        }
                    }
                }
                Section("job.section.rate") {
                    Toggle("job.useCustomRate", isOn: $useCustomRate)
                    if useCustomRate {
                        HStack {
                            Text("field.rate")
                            Spacer()
                            TextField("field.rate", value: $rate, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
                Section("field.notes") {
                    TextField("field.notes", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .navigationTitle(job == nil ? "job.titleNew" : "job.titleEdit")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save") { save() }
                        .disabled(!canSave)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        if let j = job {
            title = j.title
            clientId = j.clientId
            status = j.jobStatus
            if let r = j.defaultRate {
                useCustomRate = true
                rate = r
            }
            notes = j.notes ?? ""
        } else {
            clientId = presetClientId ?? store.activeClients().first?.id
            rate = store.settings.defaultRate
        }
    }

    private func save() {
        guard let cid = clientId else { return }
        var result = job ?? Job(clientId: cid, title: "",
                                status: JobStatus.active.rawValue,
                                defaultRate: nil, notes: nil)
        result.clientId = cid
        result.title = title.trimmingCharacters(in: .whitespaces)
        result.jobStatus = status
        result.defaultRate = useCustomRate ? rate : nil
        result.notes = notes.isEmpty ? nil : notes
        store.upsert(result)
        dismiss()
    }
}
