import Foundation

extension URL {
    static var ghostNodeDocuments: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    static func newGhostNodeDocument(basedOn originalName: String? = nil) -> URL {
        let trimmed = originalName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = trimmed.flatMap { $0.isEmpty ? nil : $0 } ?? "Scan \(documentTimestamp)"
        return uniqueDocumentURL(base: base, pathExtension: "pdf")
    }

    private static func uniqueDocumentURL(base: String, pathExtension: String) -> URL {
        let directory = ghostNodeDocuments
        var candidate = directory
            .appendingPathComponent(base)
            .appendingPathExtension(pathExtension)
        var counter = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = directory
                .appendingPathComponent("\(base) \(counter)")
                .appendingPathExtension(pathExtension)
            counter += 1
        }
        return candidate
    }

    private static var documentTimestamp: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH.mm.ss"
        return formatter.string(from: Date())
    }
}
