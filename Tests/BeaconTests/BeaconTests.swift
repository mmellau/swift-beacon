import Testing
import SwiftUI
@testable import Beacon

extension Tag {
    @Tag static var coordinator: Self
    @Tag static var region: Self
    @Tag static var sequence: Self
    @Tag static var validation: Self
    @Tag static var asyncAPI: Self
    @Tag static var accessory: Self
}

private let testFrame = CGRect(x: 100, y: 100, width: 50, height: 50)

@MainActor
private func makeTestCoordinator() -> BeaconCoordinator {
    BeaconCoordinator(windowManager: .mock)
}

@MainActor
private func resetBeaconState() {
    // Stop any running sequence first
    if Beacon.Sequence.isRunning {
        Beacon.Sequence.runner.stop()
    }
    // Dismiss any active presentation
    if Beacon.isPresenting {
        Beacon.coordinator.dismiss()
    }
    // Create fresh coordinator
    Beacon.coordinator = BeaconCoordinator(windowManager: .mock)
    // Create fresh runner wired to new coordinator
    Beacon.Sequence.runner = BeaconSequenceRunner(
        coordinator: Beacon.coordinator,
        windowManager: Beacon.coordinator.windowManager
    )
}

@Suite("BeaconCoordinator", .tags(.coordinator))
@MainActor
struct BeaconCoordinatorTests {

    @Test("registers and unregisters targets")
    func registerUnregister() {
        let coordinator = makeTestCoordinator()

        coordinator.register("test", frame: testFrame, shape: .circle, padding: 8)
        #expect(coordinator.registeredTargets["test"] != nil)
        #expect(coordinator.registeredTargets["test"]?.padding == 8)

        coordinator.unregister("test")
        #expect(coordinator.registeredTargets["test"] == nil)
    }

    @Test("presents and dismisses spotlights")
    func presentDismiss() {
        let coordinator = makeTestCoordinator()
        coordinator.register("test", frame: testFrame, shape: .circle, padding: 0)

        coordinator.present(["test"])
        #expect(coordinator.isPresenting)
        #expect(coordinator.activeIdentifiers.contains("test"))
        #expect(coordinator.activeRegions.count == 1)

        coordinator.dismiss()
        #expect(!coordinator.isPresenting)
        #expect(coordinator.activeIdentifiers.isEmpty)
    }

    @Test("unregistering last active target dismisses")
    func unregisterActiveTargetDismisses() {
        var hideCalled = false
        let spy = WindowManager.spy(onHide: { _ in hideCalled = true })
        let coordinator = BeaconCoordinator(windowManager: spy)

        coordinator.register("test", frame: testFrame, shape: .circle, padding: 0)
        coordinator.present(["test"])
        #expect(coordinator.isPresenting)

        coordinator.unregister("test")

        #expect(!coordinator.activeIdentifiers.contains("test"))
        #expect(hideCalled)
    }

    @Test("unregistering one of multiple targets keeps presenting")
    func unregisterOneOfMultipleDoesNotDismiss() {
        var hideCalled = false
        let spy = WindowManager.spy(onHide: { _ in hideCalled = true })
        let coordinator = BeaconCoordinator(windowManager: spy)

        coordinator.register("a", frame: testFrame, shape: .circle, padding: 0)
        coordinator.register("b", frame: testFrame, shape: .circle, padding: 0)
        coordinator.present(["a", "b"])

        coordinator.unregister("a")

        #expect(!coordinator.activeIdentifiers.contains("a"))
        #expect(coordinator.activeIdentifiers.contains("b"))
        #expect(coordinator.isPresenting)
        #expect(!hideCalled)
    }

    @Test("interaction handler is invoked correctly")
    func interactionHandlerInvoked() {
        let coordinator = makeTestCoordinator()
        coordinator.register("test", frame: testFrame, shape: .circle, padding: 0)

        var interactions: [BeaconTapResult] = []

        coordinator.present(
            ["test"],
            onInteraction: { interaction in
                interactions.append(interaction)
            }
        )

        coordinator.handleInteraction(.tappedOutside)
        coordinator.handleInteraction(.tappedRegion("test"))

        #expect(interactions.count == 2)
        #expect(interactions[0] == .tappedOutside)
        #expect(interactions[1] == .tappedRegion("test"))
    }

    @Test("handler receives .dismissed on dismiss()")
    func handlerReceivesDismissed() {
        let coordinator = makeTestCoordinator()
        coordinator.register("test", frame: testFrame, shape: .circle, padding: 0)

        var receivedDismissed = false

        coordinator.present(
            ["test"],
            onInteraction: { interaction in
                if interaction == .dismissed {
                    receivedDismissed = true
                }
            }
        )

        coordinator.dismiss()

        #expect(receivedDismissed)

        coordinator.unregister("test")
    }

    @Test("handler receives .dismissed when replaced")
    func handlerReceivesDismissedWhenReplaced() {
        let coordinator = makeTestCoordinator()
        coordinator.register("first", frame: testFrame, shape: .circle, padding: 0)
        coordinator.register("second", frame: testFrame, shape: .circle, padding: 0)

        var firstReceivedDismissed = false

        coordinator.present(
            ["first"],
            onInteraction: { interaction in
                if interaction == .dismissed {
                    firstReceivedDismissed = true
                }
            }
        )

        coordinator.present(["second"])

        #expect(firstReceivedDismissed)

        coordinator.dismiss()
        coordinator.unregister("first")
        coordinator.unregister("second")
    }
}

/// Test case for parameterized cornerRadius testing.
struct CornerRadiusCase: CustomTestStringConvertible, Sendable {
    let shape: BeaconShape
    let frame: CGRect
    let expectedRadius: CGFloat

    nonisolated var testDescription: String {
        switch shape {
        case .circle: return "circle → \(expectedRadius)"
        case .capsule: return "capsule → \(expectedRadius)"
        case .ellipse: return "ellipse → \(expectedRadius)"
        case .rectangle(let r): return "rectangle(\(r)) → \(expectedRadius)"
        }
    }

    nonisolated static let cases: [CornerRadiusCase] = [
        .init(shape: .circle, frame: CGRect(x: 0, y: 0, width: 100, height: 60), expectedRadius: 50),
        .init(shape: .capsule, frame: CGRect(x: 0, y: 0, width: 200, height: 40), expectedRadius: 20),
        .init(shape: .rectangle(cornerRadius: 12), frame: CGRect(x: 0, y: 0, width: 100, height: 100), expectedRadius: 12),
        .init(shape: .ellipse, frame: CGRect(x: 0, y: 0, width: 80, height: 120), expectedRadius: 40),
    ]
}

@Suite("BeaconRegion", .tags(.region))
struct BeaconRegionTests {

    @Test("CGRect.rounded reduces precision correctly")
    func rectRounding() {
        let original = CGRect(x: 100.123, y: 200.876, width: 50.333, height: 75.666)
        let rounded = original.rounded(toNearest: 0.5)

        #expect(rounded.origin.x == 100.0)
        #expect(rounded.origin.y == 201.0)
        #expect(rounded.width == 50.5)
        #expect(rounded.height == 75.5)
    }

    @Test("paddedFrame expands rectangle by padding")
    func paddedFrameRectangle() {
        let region = BeaconRegion(
            id: "test",
            frame: CGRect(x: 100, y: 100, width: 50, height: 50),
            shape: .rectangle(cornerRadius: 0),
            padding: 10
        )

        let padded = region.paddedFrame
        #expect(padded.origin.x == 90)
        #expect(padded.origin.y == 90)
        #expect(padded.width == 70)
        #expect(padded.height == 70)
    }

    @Test("paddedFrame for circle returns centered square")
    func paddedFrameCircle() {
        let region = BeaconRegion(
            id: "test",
            frame: CGRect(x: 100, y: 100, width: 80, height: 40),
            shape: .circle,
            padding: 10
        )

        let padded = region.paddedFrame
        #expect(padded.width == padded.height) // Square
        #expect(padded.width == 100)
        #expect(padded.midX == 140) // Original midX
        #expect(padded.midY == 120) // Original midY
    }

    @Test("cornerRadius calculation", arguments: CornerRadiusCase.cases)
    func cornerRadius(testCase: CornerRadiusCase) {
        let region = BeaconRegion(
            id: "test",
            frame: testCase.frame,
            shape: testCase.shape,
            padding: 0
        )
        #expect(region.cornerRadius == testCase.expectedRadius)
    }
}

@Suite("BeaconSequenceRunner", .tags(.sequence))
@MainActor
struct BeaconSequenceRunnerTests {

    @Test("run starts sequence and stop clears state")
    func runAndStop() {
        let coordinator = makeTestCoordinator()
        coordinator.register("step1", frame: testFrame, shape: .circle, padding: 0)

        let runner = BeaconSequenceRunner(coordinator: coordinator, windowManager: .mock)
        let sequence = BeaconSequence { BeaconStep(targets: ["step1"]) }

        runner.run(sequence)
        #expect(runner.isRunning)
        #expect(runner.currentStep == 0)
        #expect(runner.totalSteps == 1)

        runner.stop()
        #expect(!runner.isRunning)
    }

    @Test("next and previous navigate steps")
    func navigation() async throws {
        let coordinator = makeTestCoordinator()
        coordinator.register("a", frame: testFrame, shape: .circle, padding: 0)
        coordinator.register("b", frame: testFrame, shape: .circle, padding: 0)
        coordinator.register("c", frame: testFrame, shape: .circle, padding: 0)

        let runner = BeaconSequenceRunner(coordinator: coordinator, windowManager: .mock)
        let sequence = BeaconSequence {
            BeaconStep(targets: ["a"])
            BeaconStep(targets: ["b"])
            BeaconStep(targets: ["c"])
        }

        runner.run(sequence)
        try await Task.sleep(for: .milliseconds(50))
        #expect(runner.currentStep == 0)

        runner.next()
        try await Task.sleep(for: .milliseconds(50))
        #expect(runner.currentStep == 1)

        runner.next()
        try await Task.sleep(for: .milliseconds(50))
        #expect(runner.currentStep == 2)

        runner.previous()
        try await Task.sleep(for: .milliseconds(50))
        #expect(runner.currentStep == 1)

        runner.stop()
    }

    @Test("sequence finishes when advanced past last step")
    func sequenceFinishes() {
        let coordinator = makeTestCoordinator()
        coordinator.register("only", frame: testFrame, shape: .circle, padding: 0)

        let runner = BeaconSequenceRunner(coordinator: coordinator, windowManager: .mock)
        let sequence = BeaconSequence { BeaconStep(targets: ["only"]) }

        runner.run(sequence)
        #expect(runner.isRunning)

        runner.next()
        #expect(!runner.isRunning)
    }
}

@Suite("Beacon Validation", .tags(.validation))
@MainActor
struct BeaconValidationTests {

    init() {
        resetBeaconState()
    }

    @Test("validate succeeds for registered targets")
    func validateSucceeds() throws {
        Beacon.coordinator.register("a", frame: testFrame, shape: .circle, padding: 0)
        Beacon.coordinator.register("b", frame: testFrame, shape: .circle, padding: 0)

        try Beacon.validate("a", "b")

        Beacon.coordinator.unregister("a")
        Beacon.coordinator.unregister("b")
    }

    @Test("validate throws noTargetsProvided for empty input")
    func validateEmptyThrows() {
        #expect(throws: BeaconError.noTargetsProvided) {
            try Beacon.validate([String]())
        }
    }

    @Test("validate throws targetsNotRegistered for missing targets")
    func validateMissingThrows() {
        Beacon.coordinator.register("existing", frame: testFrame, shape: .circle, padding: 0)

        #expect {
            try Beacon.validate("existing", "missing1", "missing2")
        } throws: { error in
            guard let beaconError = error as? BeaconError,
                  case .targetsNotRegistered(let ids) = beaconError else {
                return false
            }
            return ids.sorted() == ["missing1", "missing2"]
        }

        Beacon.coordinator.unregister("existing")
    }

    @Test("sequence validate identifies invalid targets")
    func sequenceValidateWithInvalid() {
        Beacon.coordinator.register("valid", frame: testFrame, shape: .circle, padding: 0)

        let result = Beacon.Sequence.validate {
            BeaconStep(targets: ["valid"])
            BeaconStep(targets: ["invalid1", "invalid2"])
        }

        #expect(!result.isFullyValid)
        #expect(result.hasInvalidTargets)
        #expect(result.stepsWithInvalidTargets.count == 1)
        #expect(result.stepsWithInvalidTargets[0].stepIndex == 1)
        #expect(Set(result.stepsWithInvalidTargets[0].invalidTargets) == ["invalid1", "invalid2"])
        #expect(result.allInvalidTargets == ["invalid1", "invalid2"])

        Beacon.coordinator.unregister("valid")
    }
}

@Suite("Async API Behavior", .tags(.asyncAPI), .serialized)
@MainActor
struct AsyncAPIBehaviorTests {

    init() {
        resetBeaconState()
    }

    @Test("sequence stops when present() called")
    func sequenceStopsOnInterrupt() {
        Beacon.coordinator.register("seq-target", frame: testFrame, shape: .circle, padding: 0)
        Beacon.coordinator.register("manual-target", frame: testFrame, shape: .circle, padding: 0)

        Beacon.Sequence.run {
            BeaconStep(targets: ["seq-target"])
        }
        #expect(Beacon.Sequence.isRunning)

        Beacon.present("manual-target")
        #expect(!Beacon.Sequence.isRunning)

        Beacon.dismiss()
        Beacon.coordinator.unregister("seq-target")
        Beacon.coordinator.unregister("manual-target")
    }

    @Test("presentAsync with no valid targets returns dismissed immediately")
    func presentAsyncNoValidTargets() async {
        // Don't register any target
        let result = await Beacon.presentAsync("nonexistent")
        #expect(result == .dismissed)
        #expect(!Beacon.isPresenting)
    }

    @Test("presentAsync resumes with dismissed when Task cancelled")
    func presentAsyncResumeOnTaskCancel() async {
        Beacon.coordinator.register("cancellation-test", frame: testFrame, shape: .circle, padding: 0)

        let task = Task {
            await Beacon.presentAsync("cancellation-test")
        }

        // Allow task to start
        await Task.yield()

        // Cancel the task
        task.cancel()

        // Wait for result
        let result = await task.value
        #expect(result == .dismissed)
        #expect(!Beacon.isPresenting)

        Beacon.coordinator.unregister("cancellation-test")
    }

    @Test("runAsync completes when Beacon.dismiss() called externally")
    func runAsyncCompletesOnExternalDismiss() async {
        Beacon.coordinator.register("step1", frame: testFrame, shape: .circle, padding: 0)

        let task = Task {
            await Beacon.Sequence.runAsync {
                BeaconStep(targets: ["step1"])
            }
            return true
        }

        // Allow sequence to start
        await Task.yield()
        #expect(Beacon.Sequence.isRunning)

        // External dismiss
        Beacon.dismiss()

        let completed = await task.value
        #expect(completed)
        #expect(!Beacon.Sequence.isRunning)

        Beacon.coordinator.unregister("step1")
    }

    @Test("runAsync auto-advances past step with no valid targets")
    func runAsyncAutoAdvancesPastInvalidStep() async {
        Beacon.coordinator.register("valid", frame: testFrame, shape: .circle, padding: 0)

        let task = Task {
            await Beacon.Sequence.runAsync {
                BeaconStep(targets: ["invalid"])
                BeaconStep(targets: ["valid"])
            }
            return true
        }

        // Wait for retry logic (5 retries × 100ms)
        try? await Task.sleep(for: .milliseconds(700))
        #expect(Beacon.Sequence.currentStep == 1)

        Beacon.Sequence.next()

        let completed = await task.value
        #expect(completed)

        Beacon.coordinator.unregister("valid")
    }
}

@Suite("Accessory Support", .tags(.accessory))
@MainActor
struct AccessoryTests {

    @Test("BeaconTarget with accessory stores configuration")
    func targetWithAccessory() {
        let target = BeaconTarget("star", alignment: .top, offset: CGSize(width: 5, height: 10)) {
            Text("Hello")
        }
        #expect(target.identifier == "star")
        #expect(target.accessory != nil)
        #expect(target.accessory?.alignment == .top)
        #expect(target.accessory?.offset == CGSize(width: 5, height: 10))
        #expect(target.accessory?.targetId == "star")
    }

    @Test("BeaconTarget without accessory has nil accessory")
    func targetWithoutAccessory() {
        let target = BeaconTarget("star")
        #expect(target.identifier == "star")
        #expect(target.accessory == nil)
    }

    @Test("BeaconTarget string literal creates plain target")
    func targetFromStringLiteral() {
        let target: BeaconTarget = "star"
        #expect(target.identifier == "star")
        #expect(target.accessory == nil)
    }

    @Test("BeaconStep with BeaconTarget array extracts accessories")
    func stepWithBeaconTargets() {
        let step = BeaconStep(targets: [
            BeaconTarget("a", alignment: .top) { Text("A") },
            BeaconTarget("b"),
            BeaconTarget("c", alignment: .leading) { Text("C") }
        ])
        #expect(step.targets == ["a", "b", "c"])
        #expect(step.accessories.count == 2)
        #expect(step.accessories[0].targetId == "a")
        #expect(step.accessories[1].targetId == "c")
    }

    @Test("BeaconStep without accessory has empty accessories")
    func stepWithoutAccessory() {
        let step = BeaconStep(targets: ["star"])
        #expect(step.accessories.isEmpty)
    }

    @Test("PresentationContext preserves accessories on unregister")
    func contextPreservesOnUnregister() {
        let coordinator = BeaconCoordinator(windowManager: .mock)
        coordinator.register("a", frame: testFrame, shape: .circle, padding: 0)
        coordinator.register("b", frame: testFrame, shape: .circle, padding: 0)

        let accessories = [AccessoryConfiguration(
            builder: { AnyView(Text("test")) },
            alignment: .top,
            offset: .zero,
            targetId: "a"
        )]

        coordinator.present(["a", "b"], accessories: accessories)
        #expect(coordinator.currentPresentation?.accessories.count == 1)

        coordinator.unregister("b")
        #expect(coordinator.currentPresentation?.accessories.count == 1)
    }

    @Test("PresentationContext preserves accessories on setInteractionHandler")
    func contextPreservesOnSetHandler() {
        let coordinator = BeaconCoordinator(windowManager: .mock)
        coordinator.register("test", frame: testFrame, shape: .circle, padding: 0)

        let accessories = [AccessoryConfiguration(
            builder: { AnyView(Text("test")) },
            alignment: .leading,
            offset: CGSize(width: 5, height: 5),
            targetId: "test"
        )]

        coordinator.present(["test"], accessories: accessories)
        coordinator.setInteractionHandler { _ in }

        #expect(coordinator.currentPresentation?.accessories.count == 1)
        #expect(coordinator.currentPresentation?.accessories.first?.alignment == .leading)
    }

    @Test("dismiss clears accessories")
    func dismissClears() {
        let coordinator = BeaconCoordinator(windowManager: .mock)
        coordinator.register("test", frame: testFrame, shape: .circle, padding: 0)

        let accessories = [AccessoryConfiguration(
            builder: { AnyView(Text("test")) },
            alignment: .top,
            offset: .zero,
            targetId: "test"
        )]

        coordinator.present(["test"], accessories: accessories)
        coordinator.dismiss()
        #expect(coordinator.currentPresentation == nil)
    }
}
