public enum BeaconTapBehavior: Sendable {
    case advance
    case dismiss
    /// Action executes, then advances to next step.
    case custom(@MainActor @Sendable () -> Void)
}
