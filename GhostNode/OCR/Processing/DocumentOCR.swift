import Foundation
import ImageIO
import os
import Vision

nonisolated enum DocumentOCR {
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, *)
    static func processWithRecognizeDocumentsRequest(
        imageData: Data
    ) async -> OCRResult? {
        guard let cgImage = makeCGImage(from: imageData) else { return nil }

        let handler = ImageRequestHandler(cgImage)
        var request = RecognizeDocumentsRequest()
        request.textRecognitionOptions.automaticallyDetectLanguage = true
        request.setPreferredRecognitionLanguages()
        request.textRecognitionOptions.minimumTextHeightFraction = 0.005
        request.textRecognitionOptions.useLanguageCorrection = true

        do {
            let observations = try await handler.perform(request)
            return parseObservations(observations)
        } catch {
            Logger.ocr.error("RecognizeDocumentsRequest failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    static func processWithVNRecognizeTextRequest(
        imageData: Data
    ) -> OCRResult? {
        guard let cgImage = makeCGImage(from: imageData) else { return nil }

        let request = VNRecognizeTextRequest()
        request.setPreferredRecognitionLanguages()
        request.minimumTextHeight = 0.005
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            Logger.ocr.error("VNRecognizeTextRequest failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }

        guard let observations = request.results else { return nil }
        return parseObservations(observations)
    }

    private static func makeCGImage(from data: Data) -> CGImage? {
        guard let provider = CGDataProvider(data: data as CFData),
              let source = CGImageSourceCreateWithDataProvider(provider, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else { return nil }
        return cgImage
    }

    private static func parseObservations(
        _ observations: [VNRecognizedTextObservation]
    ) -> OCRResult {
        let lines = observations.map { OCRLine(from: $0) }
        let allParagraphs = lines.map { OCRParagraph(lines: [$0]) }
        let allWords = lines.flatMap(\.words)
        let transcript = lines.map(\.text).joined(separator: "\n")

        return OCRResult(
            fullTranscript: transcript,
            paragraphs: allParagraphs,
            words: allWords
        )
    }

    @available(iOS 26.0, macOS 26.0, tvOS 26.0, *)
    private static func parseObservations(_ observations: [DocumentObservation])
        -> OCRResult
    {
        let allParagraphs = observations.flatMap {
            $0.document.paragraphs.map(OCRParagraph.init)
        }
        let allWords = observations.flatMap {
            $0.document.text.words?.map(OCRWord.init) ?? []
        }
        let transcript = observations.map(\.document.text.transcript)
            .joined(separator: "\n")

        return OCRResult(
            fullTranscript: transcript,
            paragraphs: allParagraphs,
            words: allWords
        )
    }
}
