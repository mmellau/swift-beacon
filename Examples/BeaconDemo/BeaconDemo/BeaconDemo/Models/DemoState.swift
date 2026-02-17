import SwiftUI

@Observable
@MainActor
final class DemoState {
    static let shared = DemoState()

    var onboardingComplete = false
    var priorityTutorialComplete = false
    var priorityTryItComplete = false

    private init() {}

    func reset() {
        onboardingComplete = false
        priorityTutorialComplete = false
        priorityTryItComplete = false
    }
}
