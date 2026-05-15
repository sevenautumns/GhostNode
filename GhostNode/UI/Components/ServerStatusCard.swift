import SwiftUI

struct ServerStatusCard: View {
    @ObservedObject var host: HTTPServerHost

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                StatusBadge(isRunning: host.isRunning)
                Spacer()
                Button(host.isRunning ? "Stop" : "Start") {
                    host.toggle()
                }
                .buttonStyle(.borderedProminent)
                .tint(host.isRunning ? .red : .green)
            }
            Text("Port: \(String(host.port))")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Divider()
            VStack(alignment: .leading, spacing: 8) {
                Text("Reachable at")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                ForEach(host.urls, id: \.url) { entry in
                    URLRow(url: entry.url, isLocal: entry.isLocal)
                }
            }
        }
        .serverCard()
    }
}

private struct StatusBadge: View {
    let isRunning: Bool

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isRunning ? Color.green : Color.red)
                .frame(width: 10, height: 10)
            Text(isRunning ? "Running" : "Stopped")
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule().fill((isRunning ? Color.green : Color.red).opacity(0.12))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isRunning ? "Server running" : "Server stopped")
    }
}

private struct URLRow: View {
    let url: String
    let isLocal: Bool

    @State private var copied = false

    var body: some View {
        Button {
            url.copyToClipboard(feedback: $copied)
        } label: {
            HStack(spacing: 8) {
                Text(url)
                    .font(.system(.footnote, design: .monospaced))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .layoutPriority(1)
                if isLocal {
                    Text("local")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule().fill(Color.secondary.opacity(0.15))
                        )
                }
                Spacer(minLength: 4)
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .font(.footnote)
                    .foregroundColor(copied ? .green : .secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(copied ? "Copied" : "Copy \(url)")
        .accessibilityHint("Double tap to copy the server URL")
    }
}
