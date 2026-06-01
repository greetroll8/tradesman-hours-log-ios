import Foundation

/// A single labor line in a report (one time block).
struct ReportLaborLine: Identifiable {
    let id: UUID
    let date: Date
    let jobTitle: String
    let rawMinutes: Int
    let billedMinutes: Int
    let rate: Double
    let billable: Bool

    var hours: Double { Double(billedMinutes) / 60.0 }
    var amount: Double { billable ? hours * rate : 0 }
}

/// A single material line in a report.
struct ReportMaterialLine: Identifiable {
    let id: UUID
    let jobTitle: String
    let name: String
    let quantity: Double
    let unitCost: Double
    let markup: Double
    let billable: Bool
    let amount: Double
}

/// Aggregated, rounding-applied data for a client over a period.
struct ReportData {
    let client: Client
    let periodStart: Date
    let periodEnd: Date
    let currency: String
    let labor: [ReportLaborLine]
    let materials: [ReportMaterialLine]

    var totalBilledMinutes: Int { labor.reduce(0) { $0 + $1.billedMinutes } }
    var laborTotal: Double { labor.reduce(0) { $0 + $1.amount } }
    var materialsTotal: Double { materials.reduce(0) { $0 + ($1.billable ? $1.amount : 0) } }
    var grandTotal: Double { laborTotal + materialsTotal }
}

enum ReportBuilder {

    /// Build report data for a client over [start, end) applying the rounding rule.
    @MainActor
    static func build(store: AppStore,
                      client: Client,
                      start: Date,
                      end: Date,
                      calendar: Calendar = .current) -> ReportData {
        let rule = store.settings.rounding

        let blocks = store.timeBlocks.filter { block in
            guard block.clientId == client.id else { return false }
            guard let ref = block.startAt ?? block.endAt else { return false }
            return ref >= start && ref < end
        }

        let labor: [ReportLaborLine] = blocks
            .sorted { ($0.startAt ?? .distantPast) < ($1.startAt ?? .distantPast) }
            .map { block in
                let net = block.netMinutes
                let billed = Rounding.apply(net, rule: rule)
                let title = store.job(block.jobId)?.title ?? ""
                return ReportLaborLine(id: block.id,
                                       date: block.startAt ?? block.endAt ?? Date(),
                                       jobTitle: title,
                                       rawMinutes: net,
                                       billedMinutes: billed,
                                       rate: block.rate,
                                       billable: block.billable)
            }

        let blockIds = Set(blocks.map { $0.id })
        let clientJobIds = Set(store.jobs(for: client.id).map { $0.id })

        // Include materials tied to a block in range, or to a client job with no block
        // but created in the period via its job (best-effort: tie by job ownership).
        let materials: [ReportMaterialLine] = store.materials
            .filter { mat in
                if let tb = mat.timeBlockId { return blockIds.contains(tb) }
                return clientJobIds.contains(mat.jobId)
            }
            .map { mat in
                let title = store.job(mat.jobId)?.title ?? ""
                return ReportMaterialLine(id: mat.id,
                                          jobTitle: title,
                                          name: mat.name,
                                          quantity: mat.quantity,
                                          unitCost: mat.unitCost,
                                          markup: mat.markup,
                                          billable: mat.billable,
                                          amount: mat.lineTotal)
            }

        return ReportData(client: client,
                          periodStart: start,
                          periodEnd: end,
                          currency: store.settings.currency,
                          labor: labor,
                          materials: materials)
    }
}
