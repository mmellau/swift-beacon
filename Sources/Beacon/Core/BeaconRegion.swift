import SwiftUI

public struct BeaconRegion: Identifiable, Equatable, Sendable {
    public let id: String
    public var frame: CGRect
    public var shape: BeaconShape = .circle
    public var padding: CGFloat = 8

    public var paddedFrame: CGRect {
        let expanded = frame.insetBy(dx: -padding, dy: -padding)
        guard case .circle = shape else { return expanded }

        let side = max(expanded.width, expanded.height)
        return CGRect(
            x: expanded.midX - side / 2,
            y: expanded.midY - side / 2,
            width: side,
            height: side
        )
    }

    public var cornerRadius: CGFloat {
        let pf = paddedFrame
        switch shape {
        case .circle:
            return max(pf.width, pf.height) / 2
        case .ellipse, .capsule:
            return min(pf.width, pf.height) / 2
        case .rectangle(let r):
            return r
        }
    }
}

extension CGRect {
    
    nonisolated func rounded(toNearest precision: CGFloat) -> CGRect {
        CGRect(
            x: (origin.x / precision).rounded() * precision,
            y: (origin.y / precision).rounded() * precision,
            width: (width / precision).rounded() * precision,
            height: (height / precision).rounded() * precision
        )
    }
}
