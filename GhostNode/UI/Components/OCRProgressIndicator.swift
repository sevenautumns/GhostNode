import SwiftUI

struct OCRProgressIndicator: View {
    let progress: OCRProgress?
    var compact: Bool = false

    var body: some View {
        Group {
            if let progress {
                if #available(iOS 16.0, macOS 13.0, *), !compact {
                    Gauge(value: progress.fraction) { EmptyView() }
                        .gaugeStyle(.accessoryCircularCapacity)
                } else {
                    ProgressView(value: progress.fraction)
                        .progressViewStyle(.linear)
                        .frame(maxWidth: compact ? .infinity : 220)
                }
            } else {
                ProgressView()
                    .controlSize(compact ? .small : .regular)
            }
        }
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        guard let progress else { return String(localized: "Preparing OCR") }
        return String(localized: "Page \(progress.completed) of \(progress.total)")
    }
}
