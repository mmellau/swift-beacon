import Foundation

/// What happens to VoiceOver focus after the spotlight is dismissed.
public enum BeaconFocusRestoration: Sendable {
    /// Posts a screen-change notification so VoiceOver picks a new focus.
    case automatic
    /// Leaves focus alone, for callers that manage it themselves.
    case none
}
