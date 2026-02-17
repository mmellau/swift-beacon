import SwiftUI
import Beacon

extension View {
    @ViewBuilder
    func applyBeaconTarget(_ id: String?, shape: BeaconShape = .circle) -> some View {
        if let id {
            self.beaconTarget(id, shape: shape)
                .accessibilityIdentifier("beacon-target-\(id)")
        } else {
            self
        }
    }
}
