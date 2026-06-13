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
            let mappedOcr = ocr?.applying(image.imageMapping)
            try builder.addPage(
                image: png,
                widthPx: UInt32(image.pixelWidth),
                heightPx: UInt32(image.pixelHeight),
                dpi: image.dpi,
                json: OCRJSONEncoder.encode(mappedOcr)
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
            results.append(page.overlayOCR)
        }
        return results
    }

    @concurrent
    static func recognize(image data: Data) async -> OCRResult? {
        guard let ocr = await OCRProcessor.processImage(data: data) else { return nil }
        guard let buffer = try? ImageBuffer(data: data) else { return ocr }
        return ocr.applying(buffer.imageMapping)
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
        var pageJSON: [String?] = []
        try await PageOCRStream.forEach(
            pdf: pdf,
            skipPagesWithText: skipPagesWithText,
            progress: progress
        ) { page in
            try pageJSON.append(OCRJSONEncoder.encode(page.overlayOCR))
        }

        do {
            try overlay(pageJSON, onto: originalData, to: url)
        } catch {
            // Retry with a PDFKit-normalized input for PDFs GhostLayer can't parse.
            guard let normalized = pdf.dataRepresentation() else { throw error }
            try overlay(pageJSON, onto: normalized, to: url)
        }
    }

    private static func overlay(_ pageJSON: [String?], onto data: Data, to url: URL) throws {
        let builder = OcrDocBuilder()
        for json in pageJSON {
            builder.addPage(json: json)
        }
        try builder.finish(overlaying: data, to: url)
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
                json: OCRJSONEncoder.encode(page.imageOCR)
            )
        }
        try builder.finish(to: url)
    }
}
