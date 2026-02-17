import SwiftUI

public struct BeaconStyle: Sendable, Equatable {
    public let color: Color
    public let opacity: Double

    public init(color: Color = .black, opacity: Double = 0.55) {
        self.color = color
        self.opacity = opacity
    }

    public static let dimmed = BeaconStyle()
    public static let light = BeaconStyle(opacity: 0.3)
    public static let dark = BeaconStyle(opacity: 0.75)
}
