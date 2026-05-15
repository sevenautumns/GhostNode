import FlyingFox
import Foundation

extension HTTPRequest {
    func bufferedBody() async throws -> Data {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("GhostNode-incoming-\(UUID().uuidString)")
        FileManager.default.createFile(atPath: url.path, contents: nil)
        defer { try? FileManager.default.removeItem(at: url) }

        let handle = try FileHandle(forWritingTo: url)
        do {
            for try await chunk in bodySequence {
                try handle.write(contentsOf: chunk)
            }
            try handle.close()
        } catch {
            try? handle.close()
            throw error
        }

        return try Data(contentsOf: url, options: .alwaysMapped)
    }
}
