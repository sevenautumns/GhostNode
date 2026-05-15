import PDFKit
import SwiftUI

#if os(iOS)
    import UIKit
#elseif os(macOS)
    import AppKit
#endif

struct PDFPreviewView: View {
    let url: URL

    var body: some View {
        PDFKitRepresentable(url: url)
            .ignoresSafeArea(edges: .bottom)
    }
}

#if os(iOS)
    private struct PDFKitRepresentable: UIViewRepresentable {
        let url: URL

        func makeUIView(context _: Context) -> PDFView {
            let view = PDFView()
            view.displayMode = .singlePageContinuous
            view.displayDirection = .vertical
            view.document = PDFDocument(url: url)
            return view
        }

        func updateUIView(_ uiView: PDFView, context _: Context) {
            if uiView.document?.documentURL != url {
                uiView.document = PDFDocument(url: url)
            }
            if !uiView.autoScales, uiView.bounds.size != .zero {
                uiView.autoScales = true
            }
        }
    }

#elseif os(macOS)
    private struct PDFKitRepresentable: NSViewRepresentable {
        let url: URL

        func makeNSView(context _: Context) -> PDFView {
            let view = PDFView()
            view.displayMode = .singlePageContinuous
            view.displayDirection = .vertical
            view.document = PDFDocument(url: url)
            return view
        }

        func updateNSView(_ nsView: PDFView, context _: Context) {
            if nsView.document?.documentURL != url {
                nsView.document = PDFDocument(url: url)
            }
            if !nsView.autoScales, nsView.bounds.size != .zero {
                nsView.autoScales = true
            }
        }
    }
#endif
