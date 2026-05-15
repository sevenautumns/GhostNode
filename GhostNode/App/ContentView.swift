import GhostNodeShared
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var scanVM: ScanFlowViewModel
    @State private var selectedTab = Tab.scan

    enum Tab: Hashable { case scan, server }

    var body: some View {
        TabView(selection: $selectedTab) {
            ScanFlowView()
                .tabItem {
                    Label("Scan", systemImage: "doc.viewfinder")
                }
                .tag(Tab.scan)

            ServerView()
                .tabItem {
                    Label("Server", systemImage: "network")
                }
                .tag(Tab.server)
        }
        .onOpenURL(perform: handleOpen)
    }

    private func handleOpen(_ url: URL) {
        selectedTab = .scan
        if url.scheme == "ghostnode" {
            handleGhostNodeScheme(url)
            return
        }
        dispatch(url)
    }

    private func dispatch(_ url: URL) {
        Task { await ingest([url]) }
    }

    private func handleGhostNodeScheme(_ url: URL) {
        let urls = SharedInbox.drain(from: url)
        guard !urls.isEmpty else {
            scanVM.report(String(localized: "No shared files found."))
            return
        }
        Task {
            await ingest(urls)
            urls.forEach { try? FileManager.default.removeItem(at: $0) }
        }
    }

    private func ingest(_ urls: [URL]) async {
        let pdfs = urls.filter { FileImporter.classify($0) == .pdf }
        let images = urls.filter { FileImporter.classify($0) == .image }

        guard !pdfs.isEmpty || !images.isEmpty else {
            scanVM.report(String(localized: "Unsupported file type."))
            return
        }

        do {
            if let firstPDF = pdfs.first {
                let data = try FileImporter.loadPDF(firstPDF)
                scanVM.stagePDF(data)
            }
            if !images.isEmpty {
                var buffers: [ImageBuffer] = []
                for imageUrl in images {
                    try buffers.append(FileImporter.loadImage(imageUrl))
                }
                scanVM.runImages(buffers)
            }
        } catch {
            scanVM.report(error.localizedDescription)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(HTTPServerHost(port: 8080, routes: []))
        .environmentObject(ActiveJobs())
        .environmentObject(ScanFlowViewModel())
}
