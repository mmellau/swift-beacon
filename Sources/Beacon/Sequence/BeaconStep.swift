import SwiftUI

public struct BeaconStep: Sendable {
    public let targets: [String]
    /// If nil, uses `Beacon.animation.cutoutTransition`.
    public let animation: Animation?
    public let tapBehavior: BeaconTapBehavior
    public let dimmedTapBehavior: BeaconDimmedTapBehavior
    /// VoiceOver announcement. Defaults to "Step X of Y" if nil.
    public let accessibilityDescription: String?
    internal let accessories: [AccessoryConfiguration]

    public init(
        targets: [String],
        animation: Animation? = nil,
        tapBehavior: BeaconTapBehavior = .advance,
        dimmedTapBehavior: BeaconDimmedTapBehavior = .ignore,
        accessibilityDescription: String? = nil
    ) {
        self.targets = targets
        self.animation = animation
        self.tapBehavior = tapBehavior
        self.dimmedTapBehavior = dimmedTapBehavior
        self.accessibilityDescription = accessibilityDescription
        self.accessories = []
    }

    public init(
        targets: [BeaconTarget],
        animation: Animation? = nil,
        tapBehavior: BeaconTapBehavior = .advance,
        dimmedTapBehavior: BeaconDimmedTapBehavior = .ignore,
        accessibilityDescription: String? = nil
    ) {
        self.targets = targets.map(\.identifier)
        self.animation = animation
        self.tapBehavior = tapBehavior
        self.dimmedTapBehavior = dimmedTapBehavior
        self.accessibilityDescription = accessibilityDescription
        self.accessories = targets.compactMap(\.accessory)
    }
}
