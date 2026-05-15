import Foundation
import GhostLayer
import PDFKit

enum OCROverlayError: Error {
    case emptyInput
    case invalidPDF
    case renderFailed(pageIndex: Int)
}

typealias OCRProgressHandler = @MainActor @Sendable (OCRProgress) -> Void

nonisolated enum OCROverlayService {
    @concurrent
    static func overlay(
        pdf data: Data,
        mode: OCRMode,
        to url: URL,
        progress: OCRProgressHandler? = nil
    ) async throws {
        let pdf = try openPDF(data)
        switch mode {
        case .skip:
            try await writeOcrOverlay(
                pdf,
                originalData: data,
                skipPagesWithText: true,
                to: url,
                progress: progress
            )
        case .all:
            try await writeOcrOverlay(
                pdf,
                originalData: data,
                skipPagesWithText: false,
                to: url,
                progress: progress
            )
        case .force:
            try await writeImageDoc(pdf, to: url, progress: progress)
        }
    }

    @concurrent
    static func overlay(
        images: [ImageBuffer],
        to url: URL,
        progress: OCRProgressHandler? = nil
    ) async throws {
        guard !images.isEmpty else { throw OCROverlayError.emptyInput }
        let builder = ImageDocBuilder()
        let total = images.count
        for (index, image) in images.enumerated() {
            try Task.checkCancellation()
            guard let png = image.data else { throw ImageBufferError.encodingFailed }
            let ocr = await OCRProcessor.processImage(data: png)
            try builder.addPage(
                image: png,
                widthPx: UInt32(image.pixelWidth),
                heightPx: UInt32(image.pixelHeight),
                dpi: image.dpi,
                json: OCRJSONEncoder.encode(ocr)
            )
            await progress?(OCRProgress(completed: index + 1, total: total))
        }
        try builder.finish(to: url)
    }

    @concurrent
    static func recognize(
        pdf data: Data,
        mode: OCRMode,
        progress: OCRProgressHandler? = nil
    ) async throws -> [OCRResult?] {
        let pdf = try openPDF(data)
        var results: [OCRResult?] = []
        results.reserveCapacity(pdf.pageCount)
        try await PageOCRStream.forEach(
            pdf: pdf,
            skipPagesWithText: mode == .skip,
            progress: progress
        ) { page in
            results.append(page.ocr)
        }
        return results
    }

    @concurrent
    static func recognize(image data: Data) async -> OCRResult? {
        await OCRProcessor.processImage(data: data)
    }

    private static func openPDF(_ data: Data) throws -> PDFDocument {
        guard let pdf = PDFDocument(data: data), pdf.pageCount > 0 else {
            throw OCROverlayError.invalidPDF
        }
        return pdf
    }

    private static func writeOcrOverlay(
        _ pdf: PDFDocument,
        originalData: Data,
        skipPagesWithText: Bool,
        to url: URL,
        progress: OCRProgressHandler? = nil
    ) async throws {
        let builder = OcrDocBuilder()
        try await PageOCRStream.forEach(
            pdf: pdf,
            skipPagesWithText: skipPagesWithText,
            progress: progress
        ) { page in
            try builder.addPage(json: OCRJSONEncoder.encode(page.ocr))
        }
        try builder.finish(overlaying: originalData, to: url)
    }

    private static func writeImageDoc(
        _ pdf: PDFDocument,
        to url: URL,
        progress: OCRProgressHandler? = nil
    ) async throws {
        let builder = ImageDocBuilder()
        try await PageOCRStream.forEach(
            pdf: pdf,
            skipPagesWithText: false,
            progress: progress
        ) { page in
            guard let rendered = page.rendered else {
                throw OCROverlayError.renderFailed(pageIndex: page.index)
            }
            try builder.addPage(
                image: rendered.pngData,
                widthPx: rendered.widthPx,
                heightPx: rendered.heightPx,
                dpi: rendered.dpi,
                json: OCRJSONEncoder.encode(page.ocr)
            )
        }
        try builder.finish(to: url)
    }
}
