import XCTest
import Foundation
// Pure-logic tests compile the units-under-test directly into the test bundle
// (Models.swift + Formatting.swift are listed in this target's sources), so no
// app host / @testable linkage is needed.

/// Pure-logic unit tests — deterministic, no UI. These are the automated proof
/// that the app's billing/time math matches the spec (sections 12 & 15).
final class LogicTests: XCTestCase {

    // Spec section 15: raw 1h7m (67 min) rounds UP per rule; exact multiples unchanged.
    func testRoundingRules() {
        XCTAssertEqual(Rounding.apply(67, rule: .none), 67)
        XCTAssertEqual(Rounding.apply(67, rule: .five), 70)
        XCTAssertEqual(Rounding.apply(67, rule: .ten), 70)
        XCTAssertEqual(Rounding.apply(67, rule: .fifteen), 75)
        XCTAssertEqual(Rounding.apply(60, rule: .fifteen), 60)
        XCTAssertEqual(Rounding.apply(0, rule: .fifteen), 0)
    }

    func testRoundingIncrements() {
        XCTAssertEqual(RoundingRule.none.minutes, 0)
        XCTAssertEqual(RoundingRule.five.minutes, 5)
        XCTAssertEqual(RoundingRule.ten.minutes, 10)
        XCTAssertEqual(RoundingRule.fifteen.minutes, 15)
    }

    func testFormatters() {
        XCTAssertEqual(Formatters.hoursMinutes(95), "1:35")
        XCTAssertEqual(Formatters.hoursMinutes(60), "1:00")
        XCTAssertEqual(Formatters.elapsedClock(3661), "01:01:01")
        XCTAssertEqual(Formatters.hoursDecimal(90), 1.5, accuracy: 0.0001)
    }

    // Spec section 11.5: material line total = quantity * unitCost * (1 + markup%).
    func testMaterialLineTotal() {
        let withMarkup = Material(id: UUID(), jobId: UUID(), timeBlockId: nil,
                                  name: "Paint", quantity: 2, unitCost: 10, markup: 20, billable: true)
        XCTAssertEqual(withMarkup.lineTotal, 24, accuracy: 0.0001)
        let noMarkup = Material(id: UUID(), jobId: UUID(), timeBlockId: nil,
                                name: "Nails", quantity: 3, unitCost: 5, markup: 0, billable: true)
        XCTAssertEqual(noMarkup.lineTotal, 15, accuracy: 0.0001)
    }

    // Spec section 11.4: net minutes excludes break and is never negative.
    func testTimeBlockNetMinutes() {
        let normal = TimeBlock(id: UUID(), clientId: UUID(), jobId: UUID(), startAt: nil, endAt: nil,
                               durationMinutes: 60, breakMinutes: 15, billable: true, rate: 50)
        XCTAssertEqual(normal.netMinutes, 45)
        let overBreak = TimeBlock(id: UUID(), clientId: UUID(), jobId: UUID(), startAt: nil, endAt: nil,
                                  durationMinutes: 10, breakMinutes: 30, billable: true, rate: 50)
        XCTAssertEqual(overBreak.netMinutes, 0)
    }

    func testSettingsDefaults() {
        let s = AppSettings()
        XCTAssertEqual(s.rounding, .none)
        XCTAssertEqual(s.currency, "USD")
        XCTAssertEqual(s.defaultRate, 50, accuracy: 0.0001)
    }
}
