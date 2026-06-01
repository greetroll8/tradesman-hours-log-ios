import SwiftUI

struct ReportsView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var subscriptions: SubscriptionManager

    @State private var selectedClientId: UUID?
    @State private var weekStart: Date = Date().startOfWeek()
    @State private var shareURL: URL?
    @State private var showShare = false
    @State private var showPaywall = false

    private var weekEnd: Date { weekStart.adding(days: 7) }

    private var selectedClient: Client? {
        guard let id = selectedClientId else { return nil }
        return store.client(id)
    }

    private var reportData: ReportData? {
        guard let client = selectedClient else { return nil }
        return ReportBuilder.build(store: store, client: client,
                                   start: weekStart, end: weekEnd)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("reports.section.selection") {
                    Picker("start.selectClient", selection: $selectedClientId) {
                        Text("start.none").tag(UUID?.none)
                        ForEach(store.activeClients()) { c in
                            Text(c.name).tag(UUID?.some(c.id))
                        }
                    }
                    HStack {
                        Button {
                            weekStart = weekStart.adding(days: -7)
                        } label: { Image(systemName: "chevron.left") }
                        Spacer()
                        VStack {
                            Text("reports.week")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(weekStart.formatted(date: .abbreviated, time: .omitted)) – \(weekEnd.adding(days: -1).formatted(date: .abbreviated, time: .omitted))")
                                .font(.subheadline)
                        }
                        Spacer()
                        Button {
                            weekStart = weekStart.adding(days: 7)
                        } label: { Image(systemName: "chevron.right") }
                    }
                    .buttonStyle(.borderless)
                }

                if let data = reportData {
                    Section("reports.section.preview") {
                        LabeledContent("report.subtotal.labor") {
                            AmountText(amount: data.laborTotal, currency: data.currency)
                        }
                        LabeledContent("job.totalHours",
                                       value: Formatters.hoursMinutes(data.totalBilledMinutes))
                        LabeledContent("report.subtotal.materials") {
                            AmountText(amount: data.materialsTotal, currency: data.currency)
                        }
                        LabeledContent("report.total") {
                            AmountText(amount: data.grandTotal, currency: data.currency)
                                .fontWeight(.semibold)
                        }
                    }

                    Section("reports.section.export") {
                        if !subscriptions.isPro {
                            Text("reports.freeExportsLeft \(subscriptions.remainingFreeExports)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Button {
                            exportPDF(data)
                        } label: {
                            Label("reports.exportPDF", systemImage: "doc.richtext")
                        }
                        Button {
                            exportCSV(data)
                        } label: {
                            Label("reports.exportCSV", systemImage: "tablecells")
                        }
                    }
                } else {
                    Section {
                        Text("reports.pickClient")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("tab.reports")
            .onAppear {
                if selectedClientId == nil {
                    selectedClientId = store.activeClients().first?.id
                }
            }
            .sheet(isPresented: $showShare) {
                if let url = shareURL {
                    ShareSheet(items: [url])
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    private func exportPDF(_ data: ReportData) {
        guard subscriptions.canExportPDF else {
            showPaywall = true
            return
        }
        do {
            let url = try PDFExporter.write(data)
            subscriptions.recordPDFExport()
            store.add(Report(clientId: data.client.id,
                             periodStart: data.periodStart,
                             periodEnd: data.periodEnd,
                             pdfPath: url.path, csvPath: nil,
                             createdAt: Date()))
            shareURL = url
            showShare = true
        } catch {
            // Export failure is non-fatal; ignore silently for this build.
        }
    }

    private func exportCSV(_ data: ReportData) {
        do {
            let url = try CSVExporter.write(data)
            store.add(Report(clientId: data.client.id,
                             periodStart: data.periodStart,
                             periodEnd: data.periodEnd,
                             pdfPath: nil, csvPath: url.path,
                             createdAt: Date()))
            shareURL = url
            showShare = true
        } catch {
            // Ignore.
        }
    }
}
