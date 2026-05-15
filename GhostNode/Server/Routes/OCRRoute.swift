import FlyingFox
import Foundation

extension HTTPHeader {
    static let accept = HTTPHeader("Accept")
}

struct OCRRoute: HTTPHandler {
    let jobs: ActiveJobs

    func handleRequest(_ request: HTTPRequest) async throws -> HTTPResponse {
        guard request.method == .POST else {
            return HTTPResponse(statusCode: .methodNotAllowed)
        }

        let jobs = jobs
        let id = await jobs.enqueue()
        defer { Task { @MainActor in jobs.finish(id: id) } }

        let mode: OCRMode
        if let raw = request.query["mode"] {
            guard let parsed = OCRMode(rawValue: raw) else {
                return HTTPResponse(statusCode: .badRequest)
            }
            mode = parsed
        } else {
            mode = .skip
        }

        let format: OutputFormat = await acceptsJSON(request) ? .json : .pdf

        let payload = try await request.bufferedBody()
        guard !payload.isEmpty else {
            return HTTPResponse(statusCode: .badRequest)
        }

        if payload.isPDF {
            await jobs.markRunning(id: id, kind: .pdf)
            return try await handlePDF(id: id, payload: payload, mode: mode, format: format)
        }
        if payload.isImage {
            await jobs.markRunning(id: id, kind: .image)
            return try await handleImage(id: id, payload: payload, format: format)
        }
        return HTTPResponse(statusCode: .unprocessableContent)
    }

    private func acceptsJSON(_ request: HTTPRequest) async -> Bool {
        guard let header = await request.headers[.accept]?.lowercased() else {
            return false
        }
        return header
            .split(whereSeparator: { ", ;".contains($0) })
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .contains { $0 == OutputFormat.json.rawValue }
    }

    private func handlePDF(
        id: UUID,
        payload: Data,
        mode: OCRMode,
        format: OutputFormat
    ) async throws -> HTTPResponse {
        let progress = progressHandler(for: id)
        if format == .json {
            let results = try await OCROverlayService.recognize(
                pdf: payload,
                mode: mode,
                progress: progress
            )
            return .json(results)
        }
        let url = URL.tempGhostNodePDF()
        try await OCROverlayService.overlay(pdf: payload, mode: mode, to: url, progress: progress)
        return pdfFileResponse(url: url)
    }

    private func handleImage(
        id: UUID,
        payload: Data,
        format: OutputFormat
    ) async throws -> HTTPResponse {
        if format == .json {
            guard let result = await OCROverlayService.recognize(image: payload) else {
                return .error(
                    message: "OCR failed",
                    statusCode: .internalServerError
                )
            }
            return .json(result)
        }
        let image = try ImageBuffer(data: payload)
        let url = URL.tempGhostNodePDF()
        try await OCROverlayService.overlay(
            images: [image],
            to: url,
            progress: progressHandler(for: id)
        )
        return pdfFileResponse(url: url)
    }

    private func progressHandler(for id: UUID) -> OCRProgressHandler {
        let jobs = jobs
        return { p in jobs.update(id: id, progress: p) }
    }

    private func pdfFileResponse(url: URL) -> HTTPResponse {
        defer { try? FileManager.default.removeItem(at: url) }
        do {
            let body = try Data(contentsOf: url, options: .alwaysMapped)
            return .pdf(body)
        } catch {
            return .error(
                message: "Failed to read generated PDF",
                statusCode: .internalServerError
            )
        }
    }
}
