import SwiftUI

#if os(iOS)
    import UIKit
#elseif os(macOS)
    import AppKit
#endif

struct ShareButton: View {
    let url: URL

    var body: some View {
        if #available(iOS 16.0, macOS 13.0, *) {
            ShareLink(item: url) {
                Image(systemName: "square.and.arrow.up")
            }
            .accessibilityLabel("Share PDF")
        } else {
            LegacyShareButton(url: url)
                .accessibilityLabel("Share PDF")
        }
    }
}

#if os(iOS)
    private struct LegacyShareButton: View {
        let url: URL
        @State private var presenting = false

        var body: some View {
            Button {
                presenting = true
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
            .sheet(isPresented: $presenting) {
                ActivityViewController(items: [url])
            }
        }
    }

    private struct ActivityViewController: UIViewControllerRepresentable {
        let items: [Any]

        func makeUIViewController(context _: Context) -> UIActivityViewController {
            UIActivityViewController(activityItems: items, applicationActivities: nil)
        }

        func updateUIViewController(
            _: UIActivityViewController,
            context _: Context
        ) {}
    }

#elseif os(macOS)
    private struct LegacyShareButton: View {
        let url: URL

        var body: some View {
            SharingServicePickerButton(url: url)
        }
    }

    private struct SharingServicePickerButton: NSViewRepresentable {
        let url: URL

        func makeNSView(context: Context) -> NSButton {
            let button = NSButton()
            button.image = NSImage(
                systemSymbolName: "square.and.arrow.up",
                accessibilityDescription: "Share"
            )
            button.bezelStyle = .regularSquare
            button.isBordered = false
            button.target = context.coordinator
            button.action = #selector(Coordinator.showPicker(_:))
            return button
        }

        func updateNSView(_: NSButton, context: Context) {
            context.coordinator.url = url
        }

        func makeCoordinator() -> Coordinator {
            Coordinator(url: url)
        }

        final class Coordinator: NSObject, NSSharingServicePickerDelegate {
            var url: URL
            init(url: URL) {
                self.url = url
            }

            @objc func showPicker(_ sender: NSButton) {
                let picker = NSSharingServicePicker(items: [url])
                picker.delegate = self
                picker.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
            }
        }
    }
#endif
