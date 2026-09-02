import SwiftUI
import UIKit

@Observable
@MainActor
final class BeaconSequenceRunner {

    private enum StepEvent {
        case interaction(BeaconInteraction)
        case advanced
    }

    private static let maxRetries = 5
    private static let retryDelay: Duration = .milliseconds(100)

    private var sequence: BeaconSequence?
    private var currentIndex: Int = 0
    private var runTask: Task<Void, Never>?
    private var interactionContinuation: CheckedContinuation<StepEvent?, Never>?

    private let windowManager: WindowManager
    private let coordinator: BeaconCoordinator

    var isRunning: Bool { sequence != nil }
    var currentStep: Int { currentIndex }
    var totalSteps: Int { sequence?.steps.count ?? 0 }
    var progress: Double {
        guard totalSteps > 0 else { return 0 }
        return Double(currentIndex + 1) / Double(totalSteps)
    }

    init(
        coordinator: BeaconCoordinator = Beacon.coordinator,
        windowManager: WindowManager = .live
    ) {
        self.coordinator = coordinator
        self.windowManager = windowManager
    }

    func run(_ sequence: BeaconSequence) {
        stop(animated: false)

        withAnimation(Beacon.animation.sequenceState) {
            self.sequence = sequence
            self.currentIndex = 0
        }

        runTask = Task { @MainActor [weak self] in
            guard let self else { return }
            await self.runSequence(sequence)
            guard !Task.isCancelled else { return }
            self.finishSequence()
        }
    }

    func runAsync(_ sequence: BeaconSequence) async {
        stop(animated: false)

        withAnimation(Beacon.animation.sequenceState) {
            self.sequence = sequence
            self.currentIndex = 0
        }

        await runSequence(sequence)
        finishSequence()
    }

    func next() {
        Beacon.log(.info, "Advancing to next step")
        guard let sequence, currentIndex < sequence.steps.count - 1 else {
            stop()
            return
        }

        interactionContinuation?.resume(returning: .advanced)
        interactionContinuation = nil
    }

    func previous() {
        guard let seq = sequence, currentIndex > 0 else { return }

        let targetIndex = currentIndex - 1

        runTask?.cancel()
        interactionContinuation?.resume(returning: nil)
        interactionContinuation = nil

        runTask = Task { @MainActor [weak self] in
            guard let self else { return }
            await self.runSequence(seq, startingAt: targetIndex)
            guard !Task.isCancelled else { return }
            self.finishSequence()
        }
    }

    func goTo(step: Int) {
        guard let seq = sequence, step >= 0, step < seq.steps.count else { return }

        runTask?.cancel()
        interactionContinuation?.resume(returning: nil)
        interactionContinuation = nil

        runTask = Task { @MainActor [weak self] in
            guard let self else { return }
            await self.runSequence(seq, startingAt: step)
            guard !Task.isCancelled else { return }
            self.finishSequence()
        }
    }

    func stop() {
        stop(animated: true)
    }

    private func stop(animated: Bool) {
        let wasRunning = sequence != nil

        runTask?.cancel()
        runTask = nil
        interactionContinuation?.resume(returning: nil)
        interactionContinuation = nil

        Beacon.log(.info, "Sequence stopped")
        if animated {
            withAnimation(Beacon.animation.sequenceState) {
                sequence = nil
                currentIndex = 0
            }
        } else {
            sequence = nil
            currentIndex = 0
        }

        if wasRunning {
            coordinator.dismiss()
        }
    }

    private func finishSequence() {
        withAnimation(Beacon.animation.sequenceState) {
            self.sequence = nil
            self.currentIndex = 0
        }
        coordinator.dismiss()
    }

    private func announceStep(_ step: BeaconStep) {
        Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(200))
            guard let self, self.sequence != nil else { return }
            let announcement = step.accessibilityDescription
                ?? "Step \(self.currentIndex + 1) of \(self.totalSteps)"
            UIAccessibility.post(notification: .announcement, argument: announcement)
        }
    }

    private func waitForTargets(_ targets: [String]) async -> [String] {
        for attempt in 1...Self.maxRetries {
            let valid = targets.filter { coordinator.registeredTargets[$0] != nil }
            if !valid.isEmpty {
                return valid
            }

            guard !Task.isCancelled else { return [] }

            Beacon.log(.info, "Step \(currentIndex + 1) waiting for targets — attempt \(attempt)/\(Self.maxRetries)")
            try? await Task.sleep(for: Self.retryDelay)
        }
        return []
    }

    private func waitForStepEvent() async -> StepEvent? {
        await withCheckedContinuation { continuation in
            self.interactionContinuation = continuation
        }
    }

    private func runSequence(_ sequence: BeaconSequence, startingAt startIndex: Int = 0) async {
        var index = startIndex

        while index < sequence.steps.count {
            guard !Task.isCancelled else { break }

            let step = sequence.steps[index]

            withAnimation(Beacon.animation.sequenceState) {
                self.currentIndex = index
            }

            Beacon.log(.info, "Showing step \(index + 1)/\(sequence.steps.count): \(step.targets)")

            let validTargets = await waitForTargets(step.targets)

            if validTargets.isEmpty {
                Beacon.log(.warning, "Step \(index + 1) has no valid targets — auto-advancing")
                index += 1
                continue
            }

            let handler: BeaconInteractionHandler = { [weak self] interaction in
                self?.interactionContinuation?.resume(returning: .interaction(interaction))
                self?.interactionContinuation = nil
            }

            coordinator.setInteractionHandler(handler)
            coordinator.updateActiveIdentifiers(
                step.targets,
                cutoutAnimation: step.animation,
                accessories: step.accessories
            )
            windowManager.showIfNeeded()
            announceStep(step)

            guard let event = await waitForStepEvent() else {
                break
            }

            switch event {
            case .interaction(.tappedOutside):
                switch step.dimmedTapBehavior {
                case .dismiss:
                    return
                case .ignore:
                    continue
                }

            case .interaction(.tappedRegion):
                switch step.tapBehavior {
                case .advance:
                    index += 1
                case .dismiss:
                    return
                case .custom(let action):
                    action()
                    index += 1
                }

            case .advanced:
                index += 1

            case .interaction(.dismissed):
                Beacon.log(.info, "Sequence interrupted by external dismiss()")
                return
            }
        }
    }
}
