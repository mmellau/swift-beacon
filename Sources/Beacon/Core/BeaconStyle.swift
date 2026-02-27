import SwiftUI

public struct BeaconStyle: Sendable, Equatable {
    public let color: Color
    public let opacity: Double
    public let textColor: Color

    public init(color: Color = .black, opacity: Double = 0.55, textColor: Color = .white) {
        self.color = color
        self.opacity = opacity
        self.textColor = textColor
    }

    public static let dimmed = BeaconStyle()
    public static let light = BeaconStyle(opacity: 0.3)
    public static let dark = BeaconStyle(opacity: 0.75)
}
