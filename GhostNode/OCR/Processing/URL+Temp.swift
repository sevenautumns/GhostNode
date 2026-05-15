import Foundation

extension URL {
    nonisolated static func tempGhostNodePDF() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("GhostNode-\(UUID().uuidString).pdf")
    }
}
