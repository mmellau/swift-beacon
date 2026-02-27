import SwiftUI

public struct BeaconStep: Sendable {
    public let targets: [String]
    /// If nil, uses `Beacon.animation.cutoutTransition`.
    public let animation: Animation?
    public let tapBehavior: BeaconTapBehavior
    public let dimmedTapBehavior: BeaconDimmedTapBehavior
    public let labelView: @MainActor () -> any View
    /// VoiceOver announcement. Defaults to "Step X of Y" if nil.
    public let accessibilityDescription: String?

    public init(
        targets: [String],
        animation: Animation? = nil,
        tapBehavior: BeaconTapBehavior = .advance,
        dimmedTapBehavior: BeaconDimmedTapBehavior = .ignore,
        @ViewBuilder labelView: @MainActor @escaping () -> some View = { EmptyView() },
        accessibilityDescription: String? = nil
    ) {
        self.targets = targets
        self.animation = animation
        self.tapBehavior = tapBehavior
        self.dimmedTapBehavior = dimmedTapBehavior
        self.labelView = labelView
        self.accessibilityDescription = accessibilityDescription
    }
}
