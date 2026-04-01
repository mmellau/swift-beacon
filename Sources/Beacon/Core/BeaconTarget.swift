import SwiftUI

public struct BeaconTarget: Sendable, ExpressibleByStringLiteral {
    public let identifier: String
    internal let accessory: AccessoryConfiguration?

    public init(_ identifier: String) {
        self.identifier = identifier
        self.accessory = nil
    }

    public init<Accessory: View>(
        _ identifier: String,
        alignment: Alignment = .bottom,
        offset: CGSize = .zero,
        @ViewBuilder accessory: @MainActor @escaping () -> Accessory
    ) {
        self.identifier = identifier
        self.accessory = AccessoryConfiguration(
            builder: { AnyView(accessory()) },
            alignment: alignment,
            offset: offset,
            targetId: identifier
        )
    }

    public init(stringLiteral value: String) {
        self.init(value)
    }
}
