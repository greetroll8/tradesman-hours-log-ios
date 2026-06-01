import Foundation

// MARK: - Client

struct Client: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var email: String?
    var phone: String?
    var defaultRate: Double
    var archivedAt: Date?

    var isArchived: Bool { archivedAt != nil }
}

// MARK: - Job

enum JobStatus: String, Codable, CaseIterable, Identifiable {
    case active
    case onHold
    case completed

    var id: String { rawValue }

    /// Localization key for display.
    var localizationKey: String {
        switch self {
        case .active: return "job.status.active"
        case .onHold: return "job.status.onHold"
        case .completed: return "job.status.completed"
        }
    }
}

struct Job: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var clientId: UUID
    var title: String
    var status: String = JobStatus.active.rawValue
    var defaultRate: Double?
    var notes: String?

    var jobStatus: JobStatus {
        get { JobStatus(rawValue: status) ?? .active }
        set { status = newValue.rawValue }
    }
}

// MARK: - TimeBlock

struct TimeBlock: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var clientId: UUID
    var jobId: UUID
    var startAt: Date?
    var endAt: Date?
    /// Raw recorded duration in minutes (before rounding rules are applied).
    var durationMinutes: Int
    var breakMinutes: Int = 0
    var billable: Bool = true
    var rate: Double

    /// Net minutes worked excluding break time, never negative.
    var netMinutes: Int {
        max(0, durationMinutes - breakMinutes)
    }

    /// Whether this block represents a currently running timer.
    var isRunning: Bool {
        startAt != nil && endAt == nil
    }
}

// MARK: - Material

struct Material: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var jobId: UUID
    var timeBlockId: UUID?
    var name: String
    var quantity: Double
    var unitCost: Double
    /// Markup as a percentage value, e.g. 20 means +20%.
    var markup: Double = 0
    var billable: Bool = true

    /// Total billable cost for this material line including markup.
    var lineTotal: Double {
        let base = quantity * unitCost
        return base * (1.0 + markup / 100.0)
    }
}

// MARK: - WorkNote

struct WorkNote: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var jobId: UUID
    var timeBlockId: UUID?
    var text: String
    var createdAt: Date = Date()
}

// MARK: - Photo

struct Photo: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var jobId: UUID
    var timeBlockId: UUID?
    var localPath: String
    var caption: String?
}

// MARK: - Report

struct Report: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var clientId: UUID
    var periodStart: Date
    var periodEnd: Date
    var pdfPath: String?
    var csvPath: String?
    var createdAt: Date = Date()
}

// MARK: - Settings

enum RoundingRule: String, Codable, CaseIterable, Identifiable {
    case none
    case five
    case ten
    case fifteen

    var id: String { rawValue }

    /// Rounding increment in minutes; 0 means no rounding.
    var minutes: Int {
        switch self {
        case .none: return 0
        case .five: return 5
        case .ten: return 10
        case .fifteen: return 15
        }
    }

    var localizationKey: String {
        switch self {
        case .none: return "rounding.none"
        case .five: return "rounding.5"
        case .ten: return "rounding.10"
        case .fifteen: return "rounding.15"
        }
    }
}

struct AppSettings: Codable, Hashable {
    var defaultRate: Double = 50
    var roundingRule: String = RoundingRule.none.rawValue
    var currency: String = "USD"
    var reminderEnabled: Bool = true

    var rounding: RoundingRule {
        get { RoundingRule(rawValue: roundingRule) ?? .none }
        set { roundingRule = newValue.rawValue }
    }
}
