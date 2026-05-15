import Combine
import Foundation

final class ActiveJobs: ObservableObject {
    enum Kind: String { case pdf = "PDF", image = "Image" }
    enum Phase: Equatable { case queued, running }

    struct Job: Identifiable, Equatable {
        let id: UUID
        var kind: Kind?
        var phase: Phase
        var progress: OCRProgress?
    }

    @Published private(set) var jobs: [Job] = []

    func enqueue() -> UUID {
        let job = Job(id: UUID(), kind: nil, phase: .queued, progress: nil)
        jobs.append(job)
        return job.id
    }

    func markRunning(id: UUID, kind: Kind) {
        guard let i = jobs.firstIndex(where: { $0.id == id }) else { return }
        jobs[i].kind = kind
        jobs[i].phase = .running
    }

    func update(id: UUID, progress: OCRProgress) {
        guard let i = jobs.firstIndex(where: { $0.id == id }) else { return }
        jobs[i].progress = progress
    }

    func finish(id: UUID) {
        jobs.removeAll { $0.id == id }
    }
}
