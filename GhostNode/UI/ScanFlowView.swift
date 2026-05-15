import SwiftUI

struct ScanFlowView: View {
    @EnvironmentObject private var vm: ScanFlowViewModel

    var body: some View {
        content
            .overlay {
                if vm.isProcessing { processingOverlay }
            }
            .sheet(isPresented: .isPresenting($vm.previewURL, onDismiss: { vm.reset() })) {
                if let url = vm.previewURL {
                    previewSheet(url: url)
                }
            }
        #if os(iOS)
            .sheet(isPresented: $vm.isScannerPresented) {
                DocumentScannerView(
                    onFinish: { buffers in
                        vm.isScannerPresented = false
                        vm.runImages(buffers)
                    },
                    onCancel: { vm.isScannerPresented = false },
                    onError: { error in
                        vm.isScannerPresented = false
                        vm.report(error.localizedDescription)
                    }
                )
                .ignoresSafeArea()
            }
        #endif
            .alert(
                "Error",
                isPresented: .isPresenting($vm.alertMessage),
                presenting: vm.alertMessage
            ) { _ in
                Button("OK") { vm.alertMessage = nil }
            } message: { message in
                Text(message)
            }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 20) {
                header

                if let pdf = vm.pendingPDF {
                    stagedPDFCard(size: pdf.count)
                }

                sourceGrid

                Spacer(minLength: 20)
            }
            .padding()
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            AboutLogo()
            Text("GhostNode Scan")
                .font(.title)
                .fontWeight(.bold)
            Text("Scan or import a document and save it as a searchable PDF.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top)
    }

    private func stagedPDFCard(size: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.richtext")
                Text("PDF ready (\(Int64(size).formatted(.byteCount(style: .file))))")
                    .fontWeight(.semibold)
                Spacer()
                Button {
                    vm.pendingPDF = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Remove staged PDF")
            }
            ModeToggleView(mode: $vm.mode)
            Button {
                vm.runPendingPDF()
            } label: {
                Label("Process PDF", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color.secondary.opacity(0.08))
        .cornerRadius(12)
    }

    private var sourceGrid: some View {
        VStack(spacing: 12) {
            #if os(iOS)
                Button {
                    vm.isScannerPresented = true
                } label: {
                    Label("Scan document", systemImage: "doc.viewfinder")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
            #endif

            PhotosImportButton(
                label: "Choose photos",
                systemImage: "photo.on.rectangle",
                onImages: { vm.runImages($0) },
                onError: { vm.report($0) }
            )
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)

            FileImportButton(
                label: "Import PDF",
                systemImage: "doc",
                handler: .pdf { vm.stagePDF($0) },
                onError: { vm.report($0) }
            )
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)

            FileImportButton(
                label: "Import images",
                systemImage: "photo.on.rectangle.angled",
                handler: .images { vm.runImages($0) },
                onError: { vm.report($0) }
            )
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
        }
    }

    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3).ignoresSafeArea()
            VStack(spacing: 16) {
                OCRProgressIndicator(progress: vm.progress)
                Button("Cancel") { vm.reset() }
                    .buttonStyle(.bordered)
            }
            .padding(24)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    @ViewBuilder
    private func previewSheet(url: URL) -> some View {
        VStack(spacing: 0) {
            HStack {
                Button("Done") { vm.reset() }
                Spacer()
                Text("Preview")
                    .fontWeight(.semibold)
                Spacer()
                ShareButton(url: url)
            }
            .padding()
            Divider()
            PDFPreviewView(url: url)
        }
        #if os(macOS)
        .frame(minWidth: 600, minHeight: 500)
        #endif
    }
}
