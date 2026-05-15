import Combine
import FlyingFox
import Foundation
import os

typealias HTTPRouteRegistration = (path: String, handler: any HTTPHandler)

final class HTTPServerHost: ObservableObject {
    struct URLEntry: Hashable {
        let url: String
        let isLocal: Bool
    }

    @Published private(set) var isRunning = false
    let port: UInt16
    let localHosts: [String]

    private let routes: [HTTPRouteRegistration]
    private var server: HTTPServer?
    private var serverTask: Task<Void, Never>?

    init(port: UInt16 = 8080, routes: [HTTPRouteRegistration]) {
        self.port = port
        self.routes = routes
        localHosts = NetworkInterfaces.localHosts()
    }

    var urls: [URLEntry] {
        var entries = localHosts.map {
            URLEntry(url: "http://\($0):\(port)", isLocal: false)
        }
        entries.append(
            URLEntry(url: "http://127.0.0.1:\(port)", isLocal: true)
        )
        return entries
    }

    var primaryHost: String {
        localHosts.first ?? "localhost"
    }

    func toggle() {
        if isRunning { stop() } else { start() }
    }

    func start() {
        guard serverTask == nil else { return }

        let server = HTTPServer(port: port, timeout: 1800)
        self.server = server
        let routes = routes
        let port = port

        serverTask = Task.detached { [weak self] in
            for route in routes {
                await server.appendRoute(
                    HTTPRoute(stringLiteral: route.path),
                    to: route.handler
                )
            }
            await self?.watchListening(of: server)

            Logger.server.notice("Starting HTTPServerHost on port \(port, privacy: .public)…")
            do {
                try await server.run()
            } catch {
                Logger.server.error("HTTPServerHost failed: \(error.localizedDescription, privacy: .public)")
            }
            await self?.didStop()
        }
    }

    func stop() {
        serverTask?.cancel()
        serverTask = nil
        let snapshot = server
        server = nil
        isRunning = false
        Task.detached { await snapshot?.stop() }
    }

    private func watchListening(of server: HTTPServer) {
        Task { [weak self] in
            try? await server.waitUntilListening()
            self?.isRunning = true
        }
    }

    private func didStop() {
        isRunning = false
        server = nil
        serverTask = nil
    }
}
