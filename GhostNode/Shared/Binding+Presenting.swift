import SwiftUI

extension Binding {
    static func isPresenting(
        _ source: Binding<(some Any)?>,
        onDismiss: @escaping () -> Void = {}
    ) -> Binding<Bool> {
        Binding<Bool>(
            get: { source.wrappedValue != nil },
            set: {
                if !$0 {
                    source.wrappedValue = nil
                    onDismiss()
                }
            }
        )
    }
}
