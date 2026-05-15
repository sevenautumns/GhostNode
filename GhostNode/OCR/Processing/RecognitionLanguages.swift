import Vision

private nonisolated func languageCode(from tag: String) -> String? {
    if #available(macOS 13, iOS 16, tvOS 16, *) {
        Locale.Language(identifier: tag).languageCode?.identifier
    } else {
        Locale(identifier: tag).languageCode
    }
}

private nonisolated func filterByPreferredLanguage<T>(
    supported: [T],
    code: (T) -> String?
) -> [T] {
    let preferred = Set(Locale.preferredLanguages.compactMap(languageCode(from:)))
    let intersection = supported.filter {
        guard let c = code($0) else { return false }
        return preferred.contains(c)
    }
    return intersection.isEmpty ? supported : intersection
}

@available(iOS 26.0, macOS 26.0, tvOS 26.0, *)
extension RecognizeDocumentsRequest {
    nonisolated mutating func setPreferredRecognitionLanguages() {
        textRecognitionOptions.recognitionLanguages = filterByPreferredLanguage(
            supported: supportedRecognitionLanguages,
            code: { $0.languageCode?.identifier }
        )
    }
}

extension VNRecognizeTextRequest {
    nonisolated func setPreferredRecognitionLanguages() {
        guard let supported = try? supportedRecognitionLanguages() else { return }
        recognitionLanguages = filterByPreferredLanguage(
            supported: supported,
            code: languageCode(from:)
        )
    }
}
