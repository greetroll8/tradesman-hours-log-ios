import Foundation

enum CSVExporter {

    /// Produce a CSV file for the report and return its URL.
    /// Columns (spec section 11): Date, Client, Job, Type, Description,
    /// Quantity/Hours, Rate/UnitCost, Markup, Billable, Amount.
    static func write(_ data: ReportData) throws -> URL {
        var rows: [String] = []
        rows.append([
            "Date", "Client", "Job", "Type", "Description",
            "Quantity/Hours", "Rate/UnitCost", "Markup", "Billable", "Amount"
        ].map(escape).joined(separator: ","))

        let df = ISO8601DateFormatter()
        df.formatOptions = [.withFullDate]

        for line in data.labor {
            rows.append([
                df.string(from: line.date),
                data.client.name,
                line.jobTitle,
                "Labor",
                "",
                String(format: "%.2f", line.hours),
                String(format: "%.2f", line.rate),
                "",
                line.billable ? "Yes" : "No",
                String(format: "%.2f", line.amount)
            ].map(escape).joined(separator: ","))
        }

        for mat in data.materials {
            rows.append([
                "",
                data.client.name,
                mat.jobTitle,
                "Material",
                mat.name,
                String(format: "%.2f", mat.quantity),
                String(format: "%.2f", mat.unitCost),
                String(format: "%.0f%%", mat.markup),
                mat.billable ? "Yes" : "No",
                String(format: "%.2f", mat.billable ? mat.amount : 0)
            ].map(escape).joined(separator: ","))
        }

        // Totals row.
        rows.append([
            "", data.client.name, "", "Total", "", "", "", "", "",
            String(format: "%.2f", data.grandTotal)
        ].map(escape).joined(separator: ","))

        let csv = rows.joined(separator: "\r\n")
        let url = exportURL(for: data, ext: "csv")
        try csv.data(using: .utf8)?.write(to: url, options: .atomic)
        return url
    }

    private static func escape(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return field
    }

    static func exportURL(for data: ReportData, ext: String) -> URL {
        let df = DateFormatter()
        df.dateFormat = "yyyyMMdd"
        let safeClient = data.client.name
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined(separator: "-")
        let name = "report-\(safeClient)-\(df.string(from: data.periodStart)).\(ext)"
        return FileManager.default.temporaryDirectory.appendingPathComponent(name)
    }
}
