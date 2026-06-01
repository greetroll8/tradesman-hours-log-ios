import Foundation

enum Rounding {
    /// Round a raw minute count up to the nearest increment defined by the rule.
    /// Reports always round up so partial increments are billed.
    static func apply(_ minutes: Int, rule: RoundingRule) -> Int {
        let inc = rule.minutes
        guard inc > 0, minutes > 0 else { return max(0, minutes) }
        let remainder = minutes % inc
        if remainder == 0 { return minutes }
        return minutes + (inc - remainder)
    }
}

enum Formatters {
    /// Locale-aware currency string for a monetary amount.
    static func currency(_ amount: Double, code: String) -> String {
        amount.formatted(.currency(code: code))
    }

    /// Format a minute count as H:MM (e.g. 95 -> "1:35").
    static func hoursMinutes(_ minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        return String(format: "%d:%02d", h, m)
    }

    /// Format a decimal hours value (e.g. 1.5h) for labor math.
    static func hoursDecimal(_ minutes: Int) -> Double {
        Double(minutes) / 60.0
    }

    /// Elapsed seconds as HH:MM:SS using monospaced-friendly digits.
    static func elapsedClock(_ seconds: Int) -> String {
        let s = max(0, seconds)
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        return String(format: "%02d:%02d:%02d", h, m, sec)
    }
}

extension Date {
    /// Start of the ISO week (Monday) containing this date.
    func startOfWeek(calendar: Calendar = .current) -> Date {
        var cal = calendar
        cal.firstWeekday = 2 // Monday
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return cal.date(from: comps) ?? self
    }

    func startOfDay(calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: self)
    }

    func adding(days: Int, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: days, to: self) ?? self
    }
}
