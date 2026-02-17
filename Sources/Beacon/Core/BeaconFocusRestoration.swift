import Foundation

/// Where VoiceOver focus moves after spotlight dismissal.
public enum BeaconFocusRestoration: Sendable {
    case highlighted
    case trigger
    case none
}
