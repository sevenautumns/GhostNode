import Foundation
import Vision

nonisolated enum OCRProcessor {
    static func processImage(data: Data) async -> OCRResult? {
        if #available(iOS 26.0, macOS 26.0, *) {
            await DocumentOCR.processWithRecognizeDocumentsRequest(
                imageData: data
            )
        } else {
            DocumentOCR.processWithVNRecognizeTextRequest(
                imageData: data
            )
        }
    }
}
