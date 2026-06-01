import SwiftUI

struct StartJobSheet: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var timer: TimerController
    @EnvironmentObject var subscriptions: SubscriptionManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedClientId: UUID?
    @State private var newClientName: String = ""
    @State private var selectedJobId: UUID?
    @State private var newJobTitle: String = ""
    @State private var startAt: Date = Date()
    @State private var rate: Double = 0
    @State private var billable: Bool = true
    @State private var showPaywall = false

    private var availableJobs: [Job] {
        guard let cid = selectedClientId else { return [] }
        return store.jobs(for: cid)
    }

    private var canStart: Bool {
        let hasClient = selectedClientId != nil || !newClientName.trimmingCharacters(in: .whitespaces).isEmpty
        let hasJob = selectedJobId != nil || !newJobTitle.trimmingCharacters(in: .whitespaces).isEmpty
        return hasClient && hasJob
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("start.client") {
                    Picker("start.selectClient", selection: $selectedClientId) {
                        Text("start.none").tag(UUID?.none)
                        ForEach(store.activeClients()) { client in
                            Text(client.name).tag(UUID?.some(client.id))
                        }
                    }
                    .onChange(of: selectedClientId) { _ in
                        selectedJobId = nil
                        applyDefaultRate()
                    }
                    TextField("start.orNewClient", text: $newClientName)
                }

                Section("start.job") {
                    if selectedClientId != nil {
                        Picker("start.selectJob", selection: $selectedJobId) {
                            Text("start.none").tag(UUID?.none)
                            ForEach(availableJobs) { job in
                                Text(job.title).tag(UUID?.some(job.id))
                            }
                        }
                        .onChange(of: selectedJobId) { _ in applyDefaultRate() }
                    }
                    TextField("start.orNewJob", text: $newJobTitle)
                }

                Section("start.details") {
                    DatePicker("start.startTime", selection: $startAt)
                    HStack {
                        Text("field.rate")
                        Spacer()
                        TextField("field.rate", value: $rate, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    Toggle("field.billable", isOn: $billable)
                }
            }
            .navigationTitle("today.startJob")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("today.startJob") { start() }
                        .disabled(!canStart)
                }
            }
            .onAppear {
                rate = store.settings.defaultRate
                if selectedClientId == nil {
                    selectedClientId = store.activeClients().first?.id
                    applyDefaultRate()
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    private func applyDefaultRate() {
        if let jid = selectedJobId, let job = store.job(jid), let r = job.defaultRate {
            rate = r
        } else if let cid = selectedClientId, let client = store.client(cid) {
            rate = client.defaultRate > 0 ? client.defaultRate : store.settings.defaultRate
        } else {
            rate = store.settings.defaultRate
        }
    }

    private func start() {
        // Resolve client (existing or create).
        let clientId: UUID
        if let cid = selectedClientId {
            clientId = cid
        } else {
            guard subscriptions.canAddClient else {
                showPaywall = true
                return
            }
            let client = Client(name: newClientName.trimmingCharacters(in: .whitespaces),
                                email: nil, phone: nil,
                                defaultRate: store.settings.defaultRate,
                                archivedAt: nil)
            store.upsert(client)
            clientId = client.id
        }

        // Resolve job (existing or create).
        let jobId: UUID
        if let jid = selectedJobId {
            jobId = jid
        } else {
            let job = Job(clientId: clientId,
                          title: newJobTitle.trimmingCharacters(in: .whitespaces),
                          status: JobStatus.active.rawValue,
                          defaultRate: nil, notes: nil)
            store.upsert(job)
            jobId = job.id
        }

        let block = timer.start(clientId: clientId, jobId: jobId,
                                startAt: startAt, rate: rate, billable: billable)
        store.upsert(block)

        // Permission + long-timer reminder per spec section 13.
        NotificationManager.requestAuthorization()
        if store.settings.reminderEnabled {
            NotificationManager.scheduleLongTimerReminder()
        }
        dismiss()
    }
}
