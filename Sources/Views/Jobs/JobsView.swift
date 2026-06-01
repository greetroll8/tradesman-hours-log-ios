import SwiftUI

struct JobsView: View {
    @EnvironmentObject var store: AppStore
    @State private var showForm = false

    var body: some View {
        NavigationStack {
            List {
                if store.jobs.isEmpty {
                    EmptyStateView(titleKey: "jobs.empty", systemImage: "hammer")
                        .listRowSeparator(.hidden)
                }
                ForEach(store.activeClients()) { client in
                    let clientJobs = store.jobs(for: client.id)
                    if !clientJobs.isEmpty {
                        Section(client.name) {
                            ForEach(clientJobs) { job in
                                NavigationLink {
                                    JobDetailView(jobId: job.id)
                                } label: {
                                    JobRow(job: job)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("tab.jobs")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showForm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("jobs.add")
                    .disabled(store.activeClients().isEmpty)
                }
            }
            .sheet(isPresented: $showForm) {
                JobFormView(job: nil)
            }
        }
    }
}

struct JobRow: View {
    @EnvironmentObject var store: AppStore
    let job: Job

    private var minutes: Int {
        store.timeBlocks(for: job.id).reduce(0) { $0 + $1.netMinutes }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(job.title)
                Text(LocalizedStringKey(job.jobStatus.localizationKey))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(Formatters.hoursMinutes(minutes))
                .font(.caption)
                .monospacedDigit()
                .foregroundColor(.secondary)
        }
    }
}
