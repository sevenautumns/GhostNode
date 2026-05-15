#if os(iOS)
    import SwiftUI
    import UIKit
    import VisionKit

    struct DocumentScannerView: UIViewControllerRepresentable {
        let onFinish: ([ImageBuffer]) -> Void
        let onCancel: () -> Void
        let onError: (Error) -> Void

        func makeCoordinator() -> Coordinator {
            Coordinator(
                onFinish: onFinish,
                onCancel: onCancel,
                onError: onError
            )
        }

        func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
            let vc = VNDocumentCameraViewController()
            vc.delegate = context.coordinator
            return vc
        }

        func updateUIViewController(
            _: VNDocumentCameraViewController,
            context _: Context
        ) {}

        final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
            let onFinish: ([ImageBuffer]) -> Void
            let onCancel: () -> Void
            let onError: (Error) -> Void

            init(
                onFinish: @escaping ([ImageBuffer]) -> Void,
                onCancel: @escaping () -> Void,
                onError: @escaping (Error) -> Void
            ) {
                self.onFinish = onFinish
                self.onCancel = onCancel
                self.onError = onError
            }

            func documentCameraViewController(
                _: VNDocumentCameraViewController,
                didFinishWith scan: VNDocumentCameraScan
            ) {
                var buffers: [ImageBuffer] = []
                buffers.reserveCapacity(scan.pageCount)
                for index in 0 ..< scan.pageCount {
                    let image = scan.imageOfPage(at: index)
                    buffers.append(ImageBuffer(image: image))
                }
                onFinish(buffers)
            }

            func documentCameraViewControllerDidCancel(
                _: VNDocumentCameraViewController
            ) {
                onCancel()
            }

            func documentCameraViewController(
                _: VNDocumentCameraViewController,
                didFailWithError error: Error
            ) {
                onError(error)
            }
        }
    }
#endif
