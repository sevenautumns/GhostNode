import Combine
import Foundation
import SwiftUI

final class ScanFlowViewModel: ObservableObject {
    @Published var isProcessing = false
    @Published var isScannerPresented = false
    @Published var previewURL: URL?
    @Published var savedURL: URL?
    @Published var alertMessage: String?
    @Published var mode: OCRMode = .skip
    @Published var pendingPDF: Data?
    @Published var progress: OCRProgress?

    private var task: Task<Void, Never>?
    private var stagedName: String?
    private var documentName: String?

    func report(_ message: String) {
        alertMessage = message
    }

    func stagePDF(_ data: Data, name: String? = nil) {
        pendingPDF = data
        stagedName = name
    }

    func runPendingPDF() {
        guard let data = pendingPDF else { return }
        runPDF(data, mode: mode, name: stagedName)
    }

    func runPDF(_ data: Data, mode: OCRMode, name: String? = nil) {
        documentName = name
        runOverlay(onSuccess: { [weak self] in self?.pendingPDF = nil }) { url, progress in
            try await OCROverlayService.overlay(pdf: data, mode: mode, to: url, progress: progress)
        }
    }

    func runImages(_ buffers: [ImageBuffer]) {
        guard !buffers.isEmpty else { return }
        documentName = nil
        runOverlay { url, progress in
            try await OCROverlayService.overlay(images: buffers, to: url, progress: progress)
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
    }

    func save() {
        guard let source = previewURL, savedURL == nil else { return }
        do {
            let destination = URL.newGhostNodeDocument(basedOn: documentName)
            try FileManager.default.copyItem(at: source, to: destination)
            savedURL = destination
        } catch {
            alertMessage = describe(error)
        }
    }

    func reset() {
        cancel()
        if let url = previewURL {
            try? FileManager.default.removeItem(at: url)
        }
        previewURL = nil
        savedURL = nil
        isProcessing = false
        pendingPDF = nil
        stagedName = nil
        documentName = nil
        progress = nil
        mode = .skip
    }

    private func runOverlay(
        onSuccess: @escaping () -> Void = {},
        _ work: @escaping (URL, @escaping OCRProgressHandler) async throws -> Void
    ) {
        cancel()
        progress = nil
        isProcessing = true
        task = Task {
            let url = URL.tempGhostNodePDF()
            do {
                try await work(url) { [weak self] p in self?.progress = p }
                if Task.isCancelled {
                    try? FileManager.default.removeItem(at: url)
                    return
                }
                isProcessing = false
                previewURL = url
                onSuccess()
            } catch {
                try? FileManager.default.removeItem(at: url)
                if Task.isCancelled { return }
                isProcessing = false
                alertMessage = describe(error)
            }
        }
    }

    private func describe(_ error: Error) -> String {
        switch error {
        case OCROverlayError.emptyInput: String(localized: "No input.")
        case OCROverlayError.invalidPDF: String(localized: "Invalid PDF file.")
        case let OCROverlayError.renderFailed(idx):
            String(localized: "Failed to render page \(idx + 1).")
        default: error.localizedDescription
        }
    }
}
