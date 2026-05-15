#if os(iOS)
    import SwiftUI
    import UIKit

    struct ProximityScreenLockCard: View {
        let isServerRunning: Bool
        @AppStorage("server.proximityScreenLock") private var isEnabled = false

        var body: some View {
            Toggle(isOn: $isEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Turn off screen when face-down")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("Saves battery while the server runs.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .serverCard()
            .onAppear { updateProximity() }
            .onDisappear { disableProximity() }
            .onChange(of: isEnabled) { _ in updateProximity() }
            .onChange(of: isServerRunning) { _ in updateProximity() }
        }

        private func updateProximity() {
            UIDevice.current.isProximityMonitoringEnabled = isEnabled && isServerRunning
        }

        private func disableProximity() {
            UIDevice.current.isProximityMonitoringEnabled = false
        }
    }

    #Preview {
        ProximityScreenLockCard(isServerRunning: true)
            .padding()
    }
#endif
