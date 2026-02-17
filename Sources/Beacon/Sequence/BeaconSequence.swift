import SwiftUI

public struct BeaconSequence: Sendable {
    public let steps: [BeaconStep]

    /// ```swift
    /// BeaconSequence {
    ///     BeaconStep(targets: ["profile"])
    ///     BeaconStep(targets: ["settings"])
    /// }
    /// ```
    public init(@BeaconStepsBuilder builder: () -> [BeaconStep]) {
        self.steps = builder()
    }

    public init(steps: [BeaconStep]) {
        self.steps = steps
    }
}

public struct BeaconSequenceValidation: Sendable {
    public let stepsWithInvalidTargets: [(stepIndex: Int, invalidTargets: [String])]
    public let allInvalidTargets: Set<String>

    public var isFullyValid: Bool { stepsWithInvalidTargets.isEmpty }
    public var hasInvalidTargets: Bool { !stepsWithInvalidTargets.isEmpty }
}
