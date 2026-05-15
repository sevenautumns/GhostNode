import SwiftUI

#if os(iOS)
    extension Notification.Name {
        static let ghostNodeScanShortcut = Notification.Name("com.ghostnode.scan")
    }

    final class AppDelegate: NSObject, UIApplicationDelegate {
        func application(
            _: UIApplication,
            performActionFor shortcutItem: UIApplicationShortcutItem,
            completionHandler: @escaping (Bool) -> Void
        ) {
            if shortcutItem.type == "com.ghostnode.scan" {
                NotificationCenter.default.post(name: .ghostNodeScanShortcut, object: nil)
            }
            completionHandler(true)
        }
    }
#endif

@main
struct GhostNodeApp: App {
    #if os(iOS)
        @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    #endif
    @StateObject private var host: HTTPServerHost
    @StateObject private var jobs: ActiveJobs
    @StateObject private var scanViewModel = ScanFlowViewModel()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let jobs = ActiveJobs()
        _jobs = StateObject(wrappedValue: jobs)
        _host = StateObject(
            wrappedValue: HTTPServerHost(
                port: 8080,
                routes: [(path: "/api/v1/ocr", handler: OCRRoute(jobs: jobs))]
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(host)
                .environmentObject(jobs)
                .environmentObject(scanViewModel)
                .onChange(of: scenePhase) { phase in
                    apply(phase)
                }
            #if os(iOS)
                .onReceive(NotificationCenter.default.publisher(for: .ghostNodeScanShortcut)) { _ in
                    scanViewModel.isScannerPresented = true
                }
            #endif
        }
    }

    private func apply(_ phase: ScenePhase) {
        switch phase {
        case .active:
            host.start()
        case .background:
            host.stop()
        default:
            break
        }
    }
}
