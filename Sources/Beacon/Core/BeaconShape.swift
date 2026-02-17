import SwiftUI

/// Shape options for spotlight cutouts.
public enum BeaconShape: Sendable, Equatable {
    /// Circular cutout (fits to max dimension).
    case circle

    /// Rectangular cutout with optional corner radius.
    case rectangle(cornerRadius: CGFloat = 0)

    /// Pill-shaped cutout (fully rounded ends).
    case capsule

    /// Elliptical cutout (fits to frame dimensions).
    case ellipse
}
