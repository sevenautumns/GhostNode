import GhostNodeShared
import SwiftUI

#if canImport(PhotosUI)
    import PhotosUI
#endif

#if os(iOS)
    import UIKit
#elseif os(macOS)
    import AppKit
    import UniformTypeIdentifiers
#endif

struct PhotosImportButton: View {
    let label: LocalizedStringKey
    let systemImage: String
    let onImages: ([ImageBuffer]) -> Void
    let onError: (String) -> Void

    var body: some View {
        if #available(iOS 16.0, macOS 13.0, *) {
            ModernPhotosPicker(
                label: label,
                systemImage: systemImage,
                onImages: onImages,
                onError: onError
            )
        } else {
            LegacyPhotosButton(
                label: label,
                systemImage: systemImage,
                onImages: onImages,
                onError: onError
            )
        }
    }
}

@available(iOS 16.0, macOS 13.0, *)
private struct ModernPhotosPicker: View {
    let label: LocalizedStringKey
    let systemImage: String
    let onImages: ([ImageBuffer]) -> Void
    let onError: (String) -> Void

    @State private var selection: [PhotosPickerItem] = []

    var body: some View {
        let title = Text(label)
        return PhotosPicker(
            selection: $selection,
            maxSelectionCount: 50,
            matching: .images
        ) {
            Label { title } icon: { Image(systemName: systemImage) }
        }
        .onChange(of: selection) { newValue in
            guard !newValue.isEmpty else { return }
            let items = newValue
            selection = []
            Task { await load(items) }
        }
    }

    private func load(_ items: [PhotosPickerItem]) async {
        var buffers: [ImageBuffer] = []
        for item in items {
            do {
                guard let data = try await item.loadTransferable(type: Data.self)
                else { continue }
                try buffers.append(ImageBuffer(data: data))
            } catch {
                onError(error.localizedDescription)
                return
            }
        }
        guard !buffers.isEmpty else { return }
        onImages(buffers)
    }
}

#if os(iOS)
    private struct LegacyPhotosButton: View {
        let label: LocalizedStringKey
        let systemImage: String
        let onImages: ([ImageBuffer]) -> Void
        let onError: (String) -> Void

        @State private var presenting = false

        var body: some View {
            Button {
                presenting = true
            } label: {
                Label(label, systemImage: systemImage)
            }
            .sheet(isPresented: $presenting) {
                LegacyPHPickerRepresentable(
                    onImages: onImages,
                    onError: onError
                )
            }
        }
    }

    private struct LegacyPHPickerRepresentable: UIViewControllerRepresentable {
        let onImages: ([ImageBuffer]) -> Void
        let onError: (String) -> Void

        func makeCoordinator() -> Coordinator {
            Coordinator(onImages: onImages, onError: onError)
        }

        func makeUIViewController(context: Context) -> PHPickerViewController {
            var config = PHPickerConfiguration()
            config.filter = .images
            config.selectionLimit = 50
            let vc = PHPickerViewController(configuration: config)
            vc.delegate = context.coordinator
            return vc
        }

        func updateUIViewController(
            _: PHPickerViewController,
            context _: Context
        ) {}

        final class Coordinator: NSObject, PHPickerViewControllerDelegate {
            let onImages: ([ImageBuffer]) -> Void
            let onError: (String) -> Void

            init(
                onImages: @escaping ([ImageBuffer]) -> Void,
                onError: @escaping (String) -> Void
            ) {
                self.onImages = onImages
                self.onError = onError
            }

            func picker(
                _ picker: PHPickerViewController,
                didFinishPicking results: [PHPickerResult]
            ) {
                picker.dismiss(animated: true)
                let providers = results.map(\.itemProvider)
                guard !providers.isEmpty else { return }

                Task {
                    var buffers: [ImageBuffer] = []
                    for provider in providers {
                        do {
                            let id = provider.registeredTypeIdentifiers
                                .first(where: { $0.hasPrefix("public.") })
                                ?? "public.image"
                            let data = try await provider.loadData(forTypeIdentifier: id)
                            try buffers.append(ImageBuffer(data: data))
                        } catch {
                            onError(error.localizedDescription)
                            return
                        }
                    }
                    if !buffers.isEmpty {
                        onImages(buffers)
                    }
                }
            }
        }
    }

#elseif os(macOS)
    private struct LegacyPhotosButton: View {
        let label: LocalizedStringKey
        let systemImage: String
        let onImages: ([ImageBuffer]) -> Void
        let onError: (String) -> Void

        var body: some View {
            Button {
                presentOpenPanel()
            } label: {
                Label(label, systemImage: systemImage)
            }
        }

        private func presentOpenPanel() {
            let panel = NSOpenPanel()
            panel.allowsMultipleSelection = true
            panel.canChooseDirectories = false
            panel.allowedContentTypes = [.image]
            panel.begin { response in
                guard response == .OK, !panel.urls.isEmpty else { return }
                do {
                    let buffers = try panel.urls.map { url -> ImageBuffer in
                        let needsScope = url.startAccessingSecurityScopedResource()
                        defer {
                            if needsScope { url.stopAccessingSecurityScopedResource() }
                        }
                        let data = try Data(contentsOf: url)
                        return try ImageBuffer(data: data)
                    }
                    onImages(buffers)
                } catch {
                    onError(error.localizedDescription)
                }
            }
        }
    }
#endif
