import Foundation
import PDFKit

struct OCRedPage {
    let index: Int
    let rendered: RenderedPagePNG?
    let ocr: OCRResult?
}

nonisolated enum PageOCRStream {
    static func forEach(
        pdf: PDFDocument,
        skipPagesWithText: Bool,
        progress: OCRProgressHandler? = nil,
        body: (OCRedPage) async throws -> Void
    ) async throws {
        let total = pdf.pageCount
        for index in 0 ..< total {
            try Task.checkCancellation()
            let result = try await ocrPage(
                at: index,
                in: pdf,
                skipPagesWithText: skipPagesWithText
            )
            try await body(result)
            await progress?(OCRProgress(completed: index + 1, total: total))
        }
    }

    private static func ocrPage(
        at index: Int,
        in pdf: PDFDocument,
        skipPagesWithText: Bool
    ) async throws -> OCRedPage {
        guard let page = pdf.page(at: index) else {
            return OCRedPage(index: index, rendered: nil, ocr: nil)
        }
        if skipPagesWithText, pageHasText(page) {
            return OCRedPage(index: index, rendered: nil, ocr: nil)
        }
        guard let rendered = PageRenderer.renderPNG(page) else {
            throw OCROverlayError.renderFailed(pageIndex: index)
        }
        let ocr = await OCRProcessor.processImage(data: rendered.pngData)
        return OCRedPage(index: index, rendered: rendered, ocr: ocr)
    }

    private static func pageHasText(_ page: PDFPage) -> Bool {
        let text = page.string?.trimmingCharacters(in: .whitespacesAndNewlines)
        return !(text?.isEmpty ?? true)
    }
}
