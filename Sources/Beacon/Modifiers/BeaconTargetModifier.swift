import SwiftUI

struct BeaconTargetModifier: ViewModifier {
    let identifier: String
    let shape: BeaconShape
    let padding: CGFloat

    @State private var pendingFrame: CGRect = .zero
    private static let debounceDelay: Duration = .milliseconds(100)

    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGRect.self) { proxy in
                proxy.frame(in: .global).rounded(toNearest: 0.5)
            } action: { frame in
                pendingFrame = frame
            }
            .task(id: pendingFrame) {
                try? await Task.sleep(for: Self.debounceDelay)
                guard !Task.isCancelled else { return }
                Beacon.coordinator.register(
                    identifier,
                    frame: pendingFrame,
                    shape: shape,
                    padding: padding
                )
            }
            .onDisappear {
                Beacon.coordinator.unregister(identifier)
            }
    }
}

extension View {
    public func beaconTarget(
        _ identifier: String,
        shape: BeaconShape = .circle,
        padding: CGFloat = 8
    ) -> some View {
        modifier(BeaconTargetModifier(
            identifier: identifier,
            shape: shape,
            padding: padding
        ))
    }
}
