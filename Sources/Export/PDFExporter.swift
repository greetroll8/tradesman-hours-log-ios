import Foundation
import UIKit
import PDFKit

enum PDFExporter {

    /// Render a one-or-more page PDF for the report and return its URL.
    /// Sections (spec): header (client + period), labor table, materials table, totals.
    static func write(_ data: ReportData, locale: Locale = .current) throws -> URL {
        let pageWidth: CGFloat = 612   // US Letter @72dpi
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 40
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let url = CSVExporter.exportURL(for: data, ext: "pdf")

        let titleFont = UIFont.boldSystemFont(ofSize: 22)
        let headFont = UIFont.boldSystemFont(ofSize: 13)
        let bodyFont = UIFont.systemFont(ofSize: 11)
        let smallFont = UIFont.systemFont(ofSize: 10)

        let dateStyle = Date.FormatStyle(date: .abbreviated, time: .omitted).locale(locale)

        let pdfData = renderer.pdfData { ctx in
            ctx.beginPage()
            var y: CGFloat = margin

            func draw(_ text: String, font: UIFont, x: CGFloat = margin, color: UIColor = .black) {
                let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
                text.draw(at: CGPoint(x: x, y: y), withAttributes: attrs)
            }

            func newPageIfNeeded(_ rowHeight: CGFloat) {
                if y + rowHeight > pageHeight - margin {
                    ctx.beginPage()
                    y = margin
                }
            }

            // Header
            draw(String(localized: "report.pdf.title"), font: titleFont)
            y += 30
            draw(data.client.name, font: headFont)
            y += 18
            let period = "\(data.periodStart.formatted(dateStyle)) – \(data.periodEnd.adding(days: -1).formatted(dateStyle))"
            draw(period, font: bodyFont, color: .darkGray)
            y += 24

            // Labor section
            draw(String(localized: "report.section.labor"), font: headFont)
            y += 18
            for line in data.labor {
                newPageIfNeeded(16)
                let dateStr = line.date.formatted(dateStyle)
                let hrs = String(format: "%.2f h", line.hours)
                let amt = Formatters.currency(line.amount, code: data.currency)
                let bill = line.billable ? "" : " (\(String(localized: "report.nonbillable")))"
                draw("\(dateStr)  ·  \(line.jobTitle)  ·  \(hrs)\(bill)", font: bodyFont)
                let amtAttrs: [NSAttributedString.Key: Any] = [.font: bodyFont]
                let amtSize = (amt as NSString).size(withAttributes: amtAttrs)
                amt.draw(at: CGPoint(x: pageWidth - margin - amtSize.width, y: y), withAttributes: amtAttrs)
                y += 16
            }
            newPageIfNeeded(20)
            draw(String(localized: "report.subtotal.labor"), font: smallFont)
            let laborTotal = Formatters.currency(data.laborTotal, code: data.currency)
            let lts = (laborTotal as NSString).size(withAttributes: [.font: headFont])
            laborTotal.draw(at: CGPoint(x: pageWidth - margin - lts.width, y: y),
                            withAttributes: [.font: headFont])
            y += 26

            // Materials section
            draw(String(localized: "report.section.materials"), font: headFont)
            y += 18
            for mat in data.materials {
                newPageIfNeeded(16)
                let desc = "\(mat.name)  ·  \(mat.jobTitle)  ·  x\(String(format: "%.2f", mat.quantity))"
                let bill = mat.billable ? "" : " (\(String(localized: "report.nonbillable")))"
                draw("\(desc)\(bill)", font: bodyFont)
                let amt = Formatters.currency(mat.billable ? mat.amount : 0, code: data.currency)
                let amtSize = (amt as NSString).size(withAttributes: [.font: bodyFont])
                amt.draw(at: CGPoint(x: pageWidth - margin - amtSize.width, y: y),
                         withAttributes: [.font: bodyFont])
                y += 16
            }
            newPageIfNeeded(20)
            draw(String(localized: "report.subtotal.materials"), font: smallFont)
            let matTotal = Formatters.currency(data.materialsTotal, code: data.currency)
            let mts = (matTotal as NSString).size(withAttributes: [.font: headFont])
            matTotal.draw(at: CGPoint(x: pageWidth - margin - mts.width, y: y),
                          withAttributes: [.font: headFont])
            y += 30

            // Grand total
            newPageIfNeeded(30)
            draw(String(localized: "report.total"), font: titleFont)
            let grand = Formatters.currency(data.grandTotal, code: data.currency)
            let gts = (grand as NSString).size(withAttributes: [.font: titleFont])
            grand.draw(at: CGPoint(x: pageWidth - margin - gts.width, y: y),
                       withAttributes: [.font: titleFont])
        }

        try pdfData.write(to: url, options: .atomic)
        return url
    }
}
