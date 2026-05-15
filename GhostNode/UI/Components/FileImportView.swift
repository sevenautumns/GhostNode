import SwiftUI
import UniformTypeIdentifiers

enum FileImportHandler {
    case pdf((Data) -> Void)
    case images(([ImageBuffer]) -> Void)
}

struct FileImportButton: View {
    let label: LocalizedStringKey
    let systemImage: String
    let handler: FileImportHandler
    let onError: (String) -> Void

    @State private var presenting = false

    var body: some View {
        Button {
            presenting = true
        } label: {
            Label(label, systemImage: systemImage)
        }
        .fileImporter(
            isPresented: $presenting,
            allowedContentTypes: allowedTypes,
            allowsMultipleSelection: allowsMultipleSelection
        ) { result in
            handle(result)
        }
    }

    private var allowedTypes: [UTType] {
        switch handler {
        case .pdf: [.pdf]
        case .images: [.image]
        }
    }

    private var allowsMultipleSelection: Bool {
        if case .images = handler { return true }
        return false
    }

    private func handle(_ result: Result<[URL], Error>) {
        switch result {
        case let .failure(error):
            onError(error.localizedDescription)
        case let .success(urls):
            Task {
                do {
                    switch handler {
                    case let .pdf(onPDF):
                        guard let url = urls.first else { return }
                        let data = try FileImporter.loadPDF(url)
                        onPDF(data)
                    case let .images(onImages):
                        var buffers: [ImageBuffer] = []
                        for url in urls {
                            try buffers.append(FileImporter.loadImage(url))
                        }
                        guard !buffers.isEmpty else { return }
                        onImages(buffers)
                    }
                } catch {
                    onError(error.localizedDescription)
                }
            }
        }
    }
}
