import SwiftUI

#if os(iOS)
    import UIKit
#elseif os(macOS)
    import AppKit
#endif

struct ServerView: View {
    @EnvironmentObject private var host: HTTPServerHost
    @EnvironmentObject private var jobs: ActiveJobs

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                ServerStatusCard(host: host)
                if !jobs.jobs.isEmpty {
                    ActiveJobsCard(jobs: jobs)
                }
                #if os(iOS)
                    ProximityScreenLockCard(isServerRunning: host.isRunning)
                #endif
                ServerEndpointsCard(host: host)
            }
            .padding()
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            AboutLogo()
            Text("GhostNode OCR Server")
                .font(.title)
                .fontWeight(.bold)
        }
    }
}

private struct ActiveJobsCard: View {
    @ObservedObject var jobs: ActiveJobs

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Active jobs")
                .font(.headline)
            let queued = jobs.jobs.filter { $0.phase == .queued }
            ForEach(jobs.jobs) { job in
                row(
                    for: job,
                    queuePosition: queued.firstIndex(of: job).map { $0 + 1 }
                )
            }
        }
        .serverCard()
    }

    private func row(for job: ActiveJobs.Job, queuePosition: Int?) -> some View {
        HStack(spacing: 12) {
            Text(job.kind?.rawValue ?? "—")
                .font(.subheadline)
                .fontWeight(.semibold)
                .frame(width: 56, alignment: .leading)
            switch job.phase {
            case .queued:
                Text("Queued #\(queuePosition ?? 0)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            case .running:
                OCRProgressIndicator(progress: job.progress, compact: true)
            }
        }
    }
}

extension String {
    func copyToClipboard(feedback: Binding<Bool>) {
        #if os(iOS)
            UIPasteboard.general.string = self
        #elseif os(macOS)
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(self, forType: .string)
        #endif
        withAnimation { feedback.wrappedValue = true }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            withAnimation { feedback.wrappedValue = false }
        }
    }
}

extension View {
    func serverCard() -> some View {
        padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(12)
    }
}

#Preview {
    ServerView()
        .environmentObject(HTTPServerHost(port: 8080, routes: []))
        .environmentObject(ActiveJobs())
}
