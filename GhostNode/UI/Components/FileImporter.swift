import Foundation
import UniformTypeIdentifiers

nonisolated enum FileImporter {
    enum Kind { case pdf, image }

    static func classify(_ url: URL) -> Kind? {
        let fromResource = (try? url.resourceValues(
            forKeys: [.contentTypeKey]
        ))?.contentType
        let fromExtension = UTType(filenameExtension: url.pathExtension)
        guard let type = fromResource ?? fromExtension else { return nil }
        if type.conforms(to: .pdf) { return .pdf }
        if type.conforms(to: .image) { return .image }
        return nil
    }

    static func loadPDF(_ url: URL) throws -> Data {
        try readSecurityScoped(url)
    }

    static func loadImage(_ url: URL) throws -> ImageBuffer {
        try ImageBuffer(data: readSecurityScoped(url))
    }

    private static func readSecurityScoped(_ url: URL) throws -> Data {
        let needsScope = url.startAccessingSecurityScopedResource()
        defer { if needsScope { url.stopAccessingSecurityScopedResource() } }
        return try Data(contentsOf: url)
    }
}
