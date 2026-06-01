import Foundation
import Combine

/// Root persisted document holding all app data as one JSON blob.
struct AppData: Codable {
    var clients: [Client] = []
    var jobs: [Job] = []
    var timeBlocks: [TimeBlock] = []
    var materials: [Material] = []
    var notes: [WorkNote] = []
    var photos: [Photo] = []
    var reports: [Report] = []
    var settings: AppSettings = AppSettings()
    /// Number of PDF exports performed (used by the free-tier paywall gate).
    var pdfExportCount: Int = 0
    /// Whether the user has unlocked Pro.
    var isPro: Bool = false
}

@MainActor
final class AppStore: ObservableObject {
    @Published var clients: [Client] = []
    @Published var jobs: [Job] = []
    @Published var timeBlocks: [TimeBlock] = []
    @Published var materials: [Material] = []
    @Published var notes: [WorkNote] = []
    @Published var photos: [Photo] = []
    @Published var reports: [Report] = []
    @Published var settings: AppSettings = AppSettings()
    @Published var pdfExportCount: Int = 0
    @Published var isPro: Bool = false

    private let fileURL: URL
    private var saveScheduled = false

    init(filename: String = "tradesman-data.json") {
        let fm = FileManager.default
        let base = (try? fm.url(for: .applicationSupportDirectory,
                                in: .userDomainMask,
                                appropriateFor: nil,
                                create: true)) ?? fm.temporaryDirectory
        let dir = base.appendingPathComponent("TradesmanHoursLog", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent(filename)
        load()
    }

    // MARK: - Persistence

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let doc = try? decoder.decode(AppData.self, from: data) else { return }
        clients = doc.clients
        jobs = doc.jobs
        timeBlocks = doc.timeBlocks
        materials = doc.materials
        notes = doc.notes
        photos = doc.photos
        reports = doc.reports
        settings = doc.settings
        pdfExportCount = doc.pdfExportCount
        isPro = doc.isPro
    }

    func save() {
        let doc = AppData(clients: clients,
                          jobs: jobs,
                          timeBlocks: timeBlocks,
                          materials: materials,
                          notes: notes,
                          photos: photos,
                          reports: reports,
                          settings: settings,
                          pdfExportCount: pdfExportCount,
                          isPro: isPro)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(doc) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    // MARK: - Clients

    func activeClients() -> [Client] {
        clients.filter { !$0.isArchived }.sorted { $0.name < $1.name }
    }

    func client(_ id: UUID) -> Client? { clients.first { $0.id == id } }

    func upsert(_ client: Client) {
        if let idx = clients.firstIndex(where: { $0.id == client.id }) {
            clients[idx] = client
        } else {
            clients.append(client)
        }
        save()
    }

    func archiveClient(_ id: UUID) {
        guard let idx = clients.firstIndex(where: { $0.id == id }) else { return }
        clients[idx].archivedAt = Date()
        save()
    }

    /// Free tier allows at most 2 active clients.
    var canAddClient: Bool {
        isPro || activeClients().count < SubscriptionLimits.freeClientLimit
    }

    // MARK: - Jobs

    func jobs(for clientId: UUID) -> [Job] {
        jobs.filter { $0.clientId == clientId }
    }

    func job(_ id: UUID) -> Job? { jobs.first { $0.id == id } }

    func upsert(_ job: Job) {
        if let idx = jobs.firstIndex(where: { $0.id == job.id }) {
            jobs[idx] = job
        } else {
            jobs.append(job)
        }
        save()
    }

    func deleteJob(_ id: UUID) {
        jobs.removeAll { $0.id == id }
        timeBlocks.removeAll { $0.jobId == id }
        materials.removeAll { $0.jobId == id }
        notes.removeAll { $0.jobId == id }
        photos.removeAll { $0.jobId == id }
        save()
    }

    // MARK: - TimeBlocks

    func timeBlocks(for jobId: UUID) -> [TimeBlock] {
        timeBlocks.filter { $0.jobId == jobId }
    }

    func upsert(_ block: TimeBlock) {
        if let idx = timeBlocks.firstIndex(where: { $0.id == block.id }) {
            timeBlocks[idx] = block
        } else {
            timeBlocks.append(block)
        }
        save()
    }

    func deleteTimeBlock(_ id: UUID) {
        timeBlocks.removeAll { $0.id == id }
        materials.removeAll { $0.timeBlockId == id }
        notes.removeAll { $0.timeBlockId == id }
        photos.removeAll { $0.timeBlockId == id }
        save()
    }

    /// The single currently running timer block, if any.
    var runningBlock: TimeBlock? {
        timeBlocks.first { $0.isRunning }
    }

    func blocks(onDay day: Date, calendar: Calendar = .current) -> [TimeBlock] {
        timeBlocks.filter { block in
            guard let ref = block.startAt ?? block.endAt else { return false }
            return calendar.isDate(ref, inSameDayAs: day)
        }
    }

    // MARK: - Materials

    func materials(for jobId: UUID) -> [Material] {
        materials.filter { $0.jobId == jobId }
    }

    func upsert(_ material: Material) {
        if let idx = materials.firstIndex(where: { $0.id == material.id }) {
            materials[idx] = material
        } else {
            materials.append(material)
        }
        save()
    }

    func deleteMaterial(_ id: UUID) {
        materials.removeAll { $0.id == id }
        save()
    }

    // MARK: - Notes

    func notes(for jobId: UUID) -> [WorkNote] {
        notes.filter { $0.jobId == jobId }.sorted { $0.createdAt > $1.createdAt }
    }

    func add(_ note: WorkNote) {
        notes.append(note)
        save()
    }

    func deleteNote(_ id: UUID) {
        notes.removeAll { $0.id == id }
        save()
    }

    // MARK: - Photos

    func photos(for jobId: UUID) -> [Photo] {
        photos.filter { $0.jobId == jobId }
    }

    func add(_ photo: Photo) {
        photos.append(photo)
        save()
    }

    func deletePhoto(_ id: UUID) {
        if let p = photos.first(where: { $0.id == id }) {
            try? FileManager.default.removeItem(atPath: p.localPath)
        }
        photos.removeAll { $0.id == id }
        save()
    }

    // MARK: - Reports

    func add(_ report: Report) {
        reports.append(report)
        save()
    }

    // MARK: - Settings

    func updateSettings(_ newValue: AppSettings) {
        settings = newValue
        save()
    }
}
