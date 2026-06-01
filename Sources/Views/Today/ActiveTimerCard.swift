import SwiftUI

/// Active timer card shown on Today and as the core of the active timer view.
struct ActiveTimerCard: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var timer: TimerController
    let block: TimeBlock

    private var clientName: String { store.client(block.clientId)?.name ?? "" }
    private var jobTitle: String { store.job(block.jobId)?.title ?? "" }

    private var elapsed: Int { timer.elapsedSeconds(for: block) }

    var body: some View {
        VStack(spacing: 14) {
            VStack(spacing: 4) {
                Text(clientName)
                    .font(.headline)
                Text(jobTitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Text(Formatters.elapsedClock(elapsed))
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundColor(.accentColor)

            if block.breakMinutes > 0 {
                Text("active.breakMinutes \(block.breakMinutes)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Button(role: .destructive) {
                stop()
            } label: {
                Label("today.stopJob", systemImage: "stop.fill")
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)

            NavigationLink {
                ActiveTimerDetailView(blockId: block.id)
            } label: {
                Label("active.openDetail", systemImage: "chevron.right")
                    .font(.subheadline)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func stop() {
        let finished = timer.stop(block)
        store.upsert(finished)
        NotificationManager.cancelLongTimerReminder()
    }
}
