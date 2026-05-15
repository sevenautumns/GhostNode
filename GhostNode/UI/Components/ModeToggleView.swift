import SwiftUI

struct ModeToggleView: View {
    @Binding var mode: OCRMode

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("OCR Mode")
                .font(.caption)
                .foregroundColor(.secondary)
            Picker("OCR Mode", selection: $mode) {
                Text("Skip").tag(OCRMode.skip)
                Text("All").tag(OCRMode.all)
                Text("Force").tag(OCRMode.force)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
    }
}
