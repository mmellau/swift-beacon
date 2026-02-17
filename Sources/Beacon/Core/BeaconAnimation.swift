import SwiftUI

/// ```swift
/// Beacon.animation = BeaconAnimation(
///     overlayAppear: .easeOut(duration: 0.4),
///     overlayDisappear: .easeIn(duration: 0.25),
///     cutoutTransition: .snappy(duration: 0.3),
///     sequenceState: .easeInOut(duration: 0.25)
/// )
/// ```
public struct BeaconAnimation: Sendable {
    public var overlayAppear: Animation
    public var overlayDisappear: Animation
    public var cutoutTransition: Animation
    public var sequenceState: Animation

    public init(
        overlayAppear: Animation = .easeOut(duration: 0.3),
        overlayDisappear: Animation = .easeIn(duration: 0.2),
        cutoutTransition: Animation = .snappy(duration: 0.35),
        sequenceState: Animation = .easeInOut(duration: 0.25)
    ) {
        self.overlayAppear = overlayAppear
        self.overlayDisappear = overlayDisappear
        self.cutoutTransition = cutoutTransition
        self.sequenceState = sequenceState
    }

    public static let `default` = BeaconAnimation()
}
