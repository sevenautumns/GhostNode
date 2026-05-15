import SwiftUI

struct ServerEndpointsCard: View {
    @ObservedObject var host: HTTPServerHost

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("curl Examples")
                .font(.headline)
            LazyVStack(spacing: 8) {
                ForEach(Array(CurlEndpoint.allCases.enumerated()), id: \.element) {
                    index, endpoint in
                    EndpointRow(
                        endpoint: endpoint,
                        command: endpoint.curlCommand(base: base),
                        initiallyExpanded: index == 0
                    )
                }
            }
        }
        .serverCard()
    }

    private var base: String {
        "http://\(host.primaryHost):\(host.port)/api/v1/ocr"
    }
}

private struct EndpointRow: View {
    let endpoint: CurlEndpoint
    let command: String
    let initiallyExpanded: Bool

    @State private var expanded: Bool
    @State private var copied = false

    init(endpoint: CurlEndpoint, command: String, initiallyExpanded: Bool) {
        self.endpoint = endpoint
        self.command = command
        self.initiallyExpanded = initiallyExpanded
        _expanded = State(initialValue: initiallyExpanded)
    }

    var body: some View {
        DisclosureGroup(isExpanded: $expanded) {
            VStack(alignment: .leading, spacing: 8) {
                Text(endpoint.description)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                HStack(alignment: .top, spacing: 8) {
                    Text(command)
                        .font(.system(.footnote, design: .monospaced))
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    Button {
                        command.copyToClipboard(feedback: $copied)
                    } label: {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            .foregroundColor(copied ? .green : .secondary)
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel(copied ? "Copied" : "Copy curl command")
                }
                .padding(8)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(6)
            }
            .padding(.top, 8)
        } label: {
            HStack(spacing: 8) {
                Text(endpoint.title).fontWeight(.semibold)
                Text("POST")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.blue))
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .padding(10)
        .background(Color.secondary.opacity(0.08))
        .cornerRadius(8)
    }
}

private enum CurlEndpoint: String, CaseIterable, Hashable {
    case pdfToPDF, imgToPDF, pdfToJson, imgToJson

    var title: String {
        switch self {
        case .pdfToPDF: "PDF → PDF"
        case .imgToPDF: "IMG → PDF"
        case .pdfToJson: "PDF → JSON"
        case .imgToJson: "IMG → JSON"
        }
    }

    var description: String {
        switch self {
        case .pdfToPDF: String(localized: "Overlay an existing PDF and return a searchable PDF.")
        case .imgToPDF: String(localized: "Turn an image into a searchable one-page PDF.")
        case .pdfToJson: String(localized: "Run OCR on a PDF and return the results as JSON.")
        case .imgToJson: String(localized: "Run OCR on an image and return the result as JSON.")
        }
    }

    func curlCommand(base: String) -> String {
        let (contentType, accept, file, output) = parts
        let outputFlag = output.map { " -o \($0)" } ?? ""
        return
            #"curl -X POST "\#(base)" -H "Content-Type: \#(contentType)" -H "Accept: \#(accept)" --data-binary @\#(file)\#(outputFlag)"#
    }

    private var parts: (contentType: String, accept: String, file: String, output: String?) {
        switch self {
        case .pdfToPDF: ("application/pdf", "application/pdf", "input.pdf", "output.pdf")
        case .imgToPDF: ("image/jpeg", "application/pdf", "input.jpg", "output.pdf")
        case .pdfToJson: ("application/pdf", "application/json", "input.pdf", nil)
        case .imgToJson: ("image/jpeg", "application/json", "input.jpg", nil)
        }
    }
}
