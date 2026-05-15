import SwiftUI

struct AboutLogo: View {
    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented = true
        } label: {
            Image("GhostIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        #if os(macOS)
            .focusable(false)
        #endif
        .accessibilityLabel("About GhostNode")
        .sheet(isPresented: $isPresented) {
            AboutSheet()
        }
    }
}

struct AboutSheet: View {
    @Environment(\.dismiss) private var dismiss

    private static let repositoryURL = URL(string: "https://github.com/sevenautumns/GhostNode")!

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("Done") { dismiss() }
            }
            .padding()

            content
        }
        #if os(macOS)
            .frame(width: 380, height: 460)
        #endif
    }

    private var content: some View {
        VStack(spacing: 20) {
            Image("GhostIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 110, height: 110)

            VStack(spacing: 4) {
                Text("GhostNode")
                    .font(.title)
                    .fontWeight(.bold)
                Text(versionString)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Text("On-device OCR for images and PDF documents.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Link(destination: Self.repositoryURL) {
                Label("View on GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .padding(.horizontal)

            Spacer(minLength: 0)

            Text("Code licensed under Apache 2.0")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 12)
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity)
    }

    private var versionString: String {
        let info = Bundle.main.infoDictionary!
        let version = info["CFBundleShortVersionString"] as! String
        let build = info["CFBundleVersion"] as! String
        return String(localized: "Version \(version) (\(build))")
    }
}

#Preview("Logo") {
    AboutLogo()
        .padding()
}

#Preview("Sheet") {
    AboutSheet()
}
