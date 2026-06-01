import SwiftUI

struct ClientsView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var subscriptions: SubscriptionManager

    @State private var showForm = false
    @State private var editing: Client?
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            List {
                if store.activeClients().isEmpty {
                    EmptyStateView(titleKey: "clients.empty", systemImage: "person.2")
                        .listRowSeparator(.hidden)
                }
                ForEach(store.activeClients()) { client in
                    NavigationLink {
                        ClientFormView(client: client)
                    } label: {
                        ClientRow(client: client)
                    }
                }
                .onDelete(perform: archive)
            }
            .navigationTitle("tab.clients")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if subscriptions.canAddClient {
                            editing = nil
                            showForm = true
                        } else {
                            showPaywall = true
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("clients.add")
                }
            }
            .sheet(isPresented: $showForm) {
                ClientFormView(client: nil)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    private func archive(_ offsets: IndexSet) {
        let list = store.activeClients()
        for index in offsets {
            store.archiveClient(list[index].id)
        }
    }
}

struct ClientRow: View {
    @EnvironmentObject var store: AppStore
    let client: Client

    private var jobCount: Int { store.jobs(for: client.id).count }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(client.name)
                .font(.body)
            HStack(spacing: 8) {
                Text("clients.jobCount \(jobCount)")
                Text("•")
                Text(Formatters.currency(client.defaultRate, code: store.settings.currency))
                    + Text("clients.perHour")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }
}
