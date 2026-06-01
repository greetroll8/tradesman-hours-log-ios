import Foundation
import Combine

/// Drives the active job timer. Elapsed time is always computed from the
/// running block's `startAt` timestamp so it survives backgrounding and relaunch.
@MainActor
final class TimerController: ObservableObject {
    /// Ticks every second only to refresh the displayed clock; not the source of truth.
    @Published private(set) var now: Date = Date()

    private var ticker: AnyCancellable?

    init() {
        ticker = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in
                self?.now = date
            }
    }

    /// Elapsed seconds for a running block, computed from its start timestamp.
    func elapsedSeconds(for block: TimeBlock) -> Int {
        guard let start = block.startAt else { return 0 }
        let end = block.endAt ?? now
        return max(0, Int(end.timeIntervalSince(start)))
    }

    /// Begin a new running timer block and return it.
    func start(clientId: UUID,
               jobId: UUID,
               startAt: Date = Date(),
               rate: Double,
               billable: Bool) -> TimeBlock {
        TimeBlock(clientId: clientId,
                  jobId: jobId,
                  startAt: startAt,
                  endAt: nil,
                  durationMinutes: 0,
                  breakMinutes: 0,
                  billable: billable,
                  rate: rate)
    }

    /// Finalize a running block: set endAt and compute durationMinutes from timestamps.
    func stop(_ block: TimeBlock, at end: Date = Date()) -> TimeBlock {
        var result = block
        let start = block.startAt ?? end
        result.endAt = end
        result.durationMinutes = max(0, Int(end.timeIntervalSince(start) / 60.0))
        return result
    }
}
