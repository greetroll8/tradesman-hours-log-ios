import SwiftUI

struct TodayView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var timer: TimerController

    @State private var showStartSheet = false
    @State private var showManualEntry = false
    @State private var showMaterialSheet = false
    @State private var showNoteSheet = false
    @State private var showPhotoPicker = false

    private var today: Date { Date() }

    private var todaysBlocks: [TimeBlock] {
        store.blocks(onDay: today).sorted {
            ($0.startAt ?? .distantPast) > ($1.startAt ?? .distantPast)
        }
    }

    /// Today's total net minutes across all blocks (running block counted live).
    private var todaysTotalMinutes: Int {
        todaysBlocks.reduce(0) { acc, block in
            if block.isRunning {
                return acc + timer.elapsedSeconds(for: block) / 60
            }
            return acc + block.netMinutes
        }
    }

    private var grouped: [(client: Client, blocks: [TimeBlock])] {
        let dict = Dictionary(grouping: todaysBlocks, by: { $0.clientId })
        return dict.compactMap { key, value in
            guard let c = store.client(key) else { return nil }
            return (c, value)
        }
        .sorted { $0.client.name < $1.client.name }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    activeCard
                    quickChips
                    dailyTotal
                    blocksList
                }
                .padding()
            }
            .navigationTitle("tab.today")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showManualEntry = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("today.addManual")
                }
            }
            .sheet(isPresented: $showStartSheet) {
                StartJobSheet()
            }
            .sheet(isPresented: $showManualEntry) {
                TimeBlockFormView(block: nil)
            }
            .sheet(isPresented: $showMaterialSheet) {
                if let running = store.runningBlock {
                    MaterialFormView(jobId: running.jobId, timeBlockId: running.id, material: nil)
                } else {
                    MissingTimerHint()
                }
            }
            .sheet(isPresented: $showNoteSheet) {
                if let running = store.runningBlock {
                    NoteFormView(jobId: running.jobId, timeBlockId: running.id)
                } else {
                    MissingTimerHint()
                }
            }
            .sheet(isPresented: $showPhotoPicker) {
                if let running = store.runningBlock {
                    PhotoPicker { path in
                        store.add(Photo(jobId: running.jobId,
                                        timeBlockId: running.id,
                                        localPath: path,
                                        caption: nil))
                    }
                } else {
                    MissingTimerHint()
                }
            }
        }
    }

    // MARK: - Active timer card

    @ViewBuilder
    private var activeCard: some View {
        if let running = store.runningBlock {
            ActiveTimerCard(block: running)
        } else {
            VStack(spacing: 16) {
                Image(systemName: "timer")
                    .font(.system(size: 40))
                    .foregroundColor(.accentColor)
                Text("today.noActiveTimer")
                    .font(.headline)
                Button {
                    showStartSheet = true
                } label: {
                    Label("today.startJob", systemImage: "play.fill")
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Quick chips

    private var quickChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                QuickChip(titleKey: "chip.break", systemImage: "pause.circle") {
                    toggleBreak()
                }
                QuickChip(titleKey: "chip.material", systemImage: "shippingbox") {
                    showMaterialSheet = true
                }
                QuickChip(titleKey: "chip.note", systemImage: "note.text") {
                    showNoteSheet = true
                }
                QuickChip(titleKey: "chip.photo", systemImage: "camera") {
                    showPhotoPicker = true
                }
            }
        }
    }

    private func toggleBreak() {
        guard var running = store.runningBlock else { return }
        // Add a 5-minute break increment as a simple quick action.
        running.breakMinutes += 5
        store.upsert(running)
    }

    // MARK: - Daily total

    private var dailyTotal: some View {
        HStack {
            Text("today.dailyTotal")
                .font(.headline)
            Spacer()
            Text("today.hoursValue \(Formatters.hoursMinutes(todaysTotalMinutes))")
                .font(.headline)
                .monospacedDigit()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Blocks list

    @ViewBuilder
    private var blocksList: some View {
        if grouped.isEmpty {
            EmptyStateView(titleKey: "today.empty", systemImage: "tray")
        } else {
            ForEach(grouped, id: \.client.id) { entry in
                VStack(alignment: .leading, spacing: 8) {
                    Text(entry.client.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.secondary)
                    ForEach(entry.blocks) { block in
                        TimeBlockRow(block: block)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

/// Hint shown when a quick action needs a running timer but none exists.
struct MissingTimerHint: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.circle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            Text("today.needRunningTimer")
                .font(.headline)
                .multilineTextAlignment(.center)
            Button("common.ok") { dismiss() }
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .presentationDetents([.height(200)])
    }
}

struct TimeBlockRow: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var timer: TimerController
    let block: TimeBlock

    private var jobTitle: String { store.job(block.jobId)?.title ?? "" }

    private var minutes: Int {
        block.isRunning ? timer.elapsedSeconds(for: block) / 60 : block.netMinutes
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(jobTitle)
                    .font(.body)
                if let start = block.startAt {
                    Text(start.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            if block.isRunning {
                Text("today.running")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.green)
            }
            Text(Formatters.hoursMinutes(minutes))
                .monospacedDigit()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
