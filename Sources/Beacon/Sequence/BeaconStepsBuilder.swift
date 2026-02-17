import SwiftUI

@resultBuilder
public struct BeaconStepsBuilder {
    public static func buildBlock(_ steps: BeaconStep...) -> [BeaconStep] {
        steps
    }

    public static func buildOptional(_ step: [BeaconStep]?) -> [BeaconStep] {
        step ?? []
    }

    public static func buildEither(first: [BeaconStep]) -> [BeaconStep] {
        first
    }

    public static func buildEither(second: [BeaconStep]) -> [BeaconStep] {
        second
    }

    public static func buildArray(_ steps: [[BeaconStep]]) -> [BeaconStep] {
        steps.flatMap { $0 }
    }
}
