import Foundation

public enum NSItemProviderLoadError: Error {
    case missingData
}

public extension NSItemProvider {
    @MainActor
    func loadData(forTypeIdentifier typeIdentifier: String) async throws -> Data {
        try await withCheckedThrowingContinuation { cont in
            loadDataRepresentation(forTypeIdentifier: typeIdentifier) { data, error in
                if let data {
                    cont.resume(returning: data)
                } else {
                    cont.resume(throwing: error ?? NSItemProviderLoadError.missingData)
                }
            }
        }
    }
}
