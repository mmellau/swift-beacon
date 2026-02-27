import SwiftUI
import os

@MainActor
public enum Beacon {

    internal static var coordinator = BeaconCoordinator()

    public static var style: BeaconStyle {
        get { coordinator.style }
        set { coordinator.style = newValue }
    }

    /// ```swift
    /// Beacon.logger = Logger(subsystem: "com.app", category: "beacon")
    /// ```
    public static var logger: Logger?

    /// ```swift
    /// Beacon.animation = BeaconAnimation(
    ///     overlayAppear: .easeOut(duration: 0.4),
    ///     overlayDisappear: .easeIn(duration: 0.25),
    ///     cutoutTransition: .snappy(duration: 0.3)
    /// )
    /// ```
    public static var animation: BeaconAnimation = .default

    public static var activeIdentifiers: Set<String> {
        coordinator.activeIdentifiers
    }

    public static var registeredTargets: [String: BeaconRegion] {
        coordinator.registeredTargets
    }

    public static var isPresenting: Bool {
        coordinator.isPresenting
    }

    public static var activeRegions: [BeaconRegion] {
        coordinator.activeRegions
    }

    public static func present(
        _ identifiers: String...,
        focusRestoration: BeaconFocusRestoration = .highlighted,
        label: Text? = nil
    ) {
        present(
            identifiers,
            onInteraction: nil,
            focusRestoration: focusRestoration,
            label: label
        )
    }

    public static func present(
        _ identifiers: [String],
        focusRestoration: BeaconFocusRestoration = .highlighted,
        label: Text? = nil
    ) {
        present(
            identifiers,
            onInteraction: nil,
            focusRestoration: focusRestoration,
            label: label
        )
    }

    internal static func present(
        _ identifiers: [String],
        onInteraction: BeaconInteractionHandler?,
        focusRestoration: BeaconFocusRestoration,
        label: Text?
    ) {
        if Sequence.isRunning {
            log(.info, "Stopping sequence — explicit present() called")
            Sequence.stop()
        }

        let missing = identifiers.filter { coordinator.registeredTargets[$0] == nil }
        if !missing.isEmpty {
            log(.warning, "Targets not registered: \(missing.joined(separator: ", "))")
        }

        let valid = identifiers.filter { coordinator.registeredTargets[$0] != nil }
        guard !valid.isEmpty else {
            log(.warning, "No valid targets to present")
            return
        }

        log(.info, "Presenting: \(valid.joined(separator: ", "))")
        coordinator.present(
            valid,
            onInteraction: onInteraction,
            focusRestoration: focusRestoration,
            labelView: {
                if let label {
                    label
                } else {
                    EmptyView()
                }
            }
        )
    }

    public static func dismiss() {
        log(.info, "Dismissing")
        coordinator.dismiss()
    }
}

extension Beacon {

    public enum Sequence {

        @MainActor
        internal static var runner = BeaconSequenceRunner(
            coordinator: Beacon.coordinator,
            windowManager: Beacon.coordinator.windowManager
        )

        /// Fire-and-forget sequence execution.
        /// Use `runAsync()` when you need to await completion.
        ///
        /// ```swift
        /// Beacon.Sequence.run {
        ///     BeaconStep(targets: ["profile"])
        ///     BeaconStep(targets: ["settings"])
        /// }
        /// ```
        @MainActor
        public static func run(@BeaconStepsBuilder _ builder: () -> [BeaconStep]) {
            let sequence = BeaconSequence(steps: builder())
            run(sequence)
        }

        @MainActor
        public static func run(_ sequence: BeaconSequence) {
            guard !sequence.steps.isEmpty else {
                Beacon.log(.warning, "Cannot run empty sequence")
                return
            }

            logUnregisteredTargets(sequence)
            Beacon.log(.info, "Starting sequence with \(sequence.steps.count) steps")
            runner.run(sequence)
        }

        @MainActor
        public static var isRunning: Bool {
            runner.isRunning
        }

        @MainActor
        public static var currentStep: Int {
            runner.currentStep
        }

        @MainActor
        public static var totalSteps: Int {
            runner.totalSteps
        }

        @MainActor
        public static var progress: Double {
            runner.progress
        }

        @MainActor
        public static func next() {
            guard runner.isRunning else {
                Beacon.log(.warning, "No active sequence to advance")
                return
            }
            runner.next()
        }

        @MainActor
        public static func previous() {
            guard runner.isRunning else {
                Beacon.log(.warning, "No active sequence to go back")
                return
            }
            runner.previous()
        }

        @MainActor
        public static func goTo(step: Int) {
            guard runner.isRunning else {
                Beacon.log(.warning, "No active sequence for goTo")
                return
            }
            runner.goTo(step: step)
        }

        @MainActor
        public static func stop() {
            guard runner.isRunning else { return }
            Beacon.log(.info, "Stopping sequence")
            runner.stop()
        }

        /// Validate a sequence against currently registered targets.
        ///
        /// Use during development/testing to catch missing targets before runtime.
        /// At runtime, steps with no valid targets auto-advance (silent skip).
        ///
        /// ```swift
        /// let result = Beacon.Sequence.validate {
        ///     BeaconStep(targets: ["profile", "settings"])
        /// }
        /// if result.hasInvalidTargets {
        ///     print("Missing targets: \(result.allInvalidTargets)")
        /// }
        /// ```
        @MainActor
        public static func validate(_ sequence: BeaconSequence) -> BeaconSequenceValidation {
            var stepsWithInvalid: [(Int, [String])] = []
            var allInvalid: Set<String> = []

            for (index, step) in sequence.steps.enumerated() {
                let invalid = step.targets.filter { Beacon.coordinator.registeredTargets[$0] == nil }
                if !invalid.isEmpty {
                    stepsWithInvalid.append((index, invalid))
                    allInvalid.formUnion(invalid)
                }
            }

            return BeaconSequenceValidation(
                stepsWithInvalidTargets: stepsWithInvalid,
                allInvalidTargets: allInvalid
            )
        }

        @MainActor
        public static func validate(@BeaconStepsBuilder _ steps: () -> [BeaconStep]) -> BeaconSequenceValidation {
            validate(BeaconSequence(steps: steps()))
        }

        /// ```swift
        /// await Beacon.Sequence.runAsync {
        ///     BeaconStep(targets: ["profile"])
        ///     BeaconStep(targets: ["settings"])
        /// }
        /// print("Sequence complete!")
        /// ```
        @MainActor
        public static func runAsync(
            @BeaconStepsBuilder _ builder: () -> [BeaconStep]
        ) async {
            await runAsync(BeaconSequence(steps: builder()))
        }

        @MainActor
        public static func runAsync(_ sequence: BeaconSequence) async {
            guard !sequence.steps.isEmpty else {
                Beacon.log(.warning, "Cannot run empty sequence")
                return
            }

            logUnregisteredTargets(sequence)
            Beacon.log(.info, "Starting sequence with \(sequence.steps.count) steps")

            await withTaskCancellationHandler {
                await runner.runAsync(sequence)
            } onCancel: {
                Task { @MainActor in
                    runner.stop()
                }
            }
        }

        @MainActor
        private static func logUnregisteredTargets(_ sequence: BeaconSequence) {
            for (index, step) in sequence.steps.enumerated() {
                let missing = step.targets.filter { Beacon.coordinator.registeredTargets[$0] == nil }
                if !missing.isEmpty {
                    Beacon.log(.warning, "Step \(index + 1) has unregistered targets: \(missing.joined(separator: ", "))")
                }
            }
        }
    }
}

extension Beacon {

    /// ```swift
    /// try Beacon.validate("star", "inbox")
    /// Beacon.present("star", "inbox")  // Guaranteed to work
    /// ```
    public static func validate(_ identifiers: String...) throws {
        try validate(identifiers)
    }

    public static func validate(_ identifiers: [String]) throws {
        guard !identifiers.isEmpty else {
            throw BeaconError.noTargetsProvided
        }

        let missing = identifiers.filter { coordinator.registeredTargets[$0] == nil }
        guard missing.isEmpty else {
            throw BeaconError.targetsNotRegistered(missing)
        }
    }
}

public enum BeaconTapResult: Sendable, Equatable {
    case tappedOutside
    case tappedRegion(String)
    case dismissed
    case advanced
}

internal typealias BeaconInteraction = BeaconTapResult
internal typealias BeaconInteractionHandler = @MainActor @Sendable (BeaconInteraction) -> Void

extension Beacon {

    /// ```swift
    /// let result = await Beacon.presentAsync("star")
    /// switch result {
    /// case .tappedOutside:
    ///     print("Dismissed by tapping outside")
    /// case .tappedRegion(let id):
    ///     print("Tapped: \(id)")
    /// case .dismissed:
    ///     print("Dismissed externally")
    /// }
    /// ```
    public static func presentAsync(
        _ identifiers: String...,
        label: Text? = nil
    ) async -> BeaconTapResult {
        await presentAsync(identifiers, label: label)
    }

    public static func presentAsync(
        _ identifiers: [String],
        label: Text? = nil
    ) async -> BeaconTapResult {
        let valid = identifiers.filter { coordinator.registeredTargets[$0] != nil }
        if valid.isEmpty {
            log(.warning, "presentAsync: No valid targets — returning .dismissed")
            return .dismissed
        }

        var isResumed = false

        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                if Task.isCancelled {
                    continuation.resume(returning: .dismissed)
                    return
                }

                let handler: BeaconInteractionHandler = { result in
                    guard !isResumed else { return }
                    isResumed = true
                    if result != .dismissed {
                        coordinator.dismiss()
                    }
                    continuation.resume(returning: result)
                }

                present(
                    identifiers,
                    onInteraction: handler,
                    focusRestoration: .highlighted,
                    label: label
                )
            }
        } onCancel: {
            Task { @MainActor in
                coordinator.dismiss()
            }
        }
    }
}

extension Beacon {
    
    public enum LogLevel: String, Sendable {
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
    }

    internal static func log(_ level: LogLevel, _ message: String) {
        guard let logger else { return }

        switch level {
        case .info:
            logger.info("[Beacon] \(message)")
        case .warning:
            logger.warning("[Beacon] \(message)")
        case .error:
            logger.error("[Beacon] \(message)")
        }
    }
}
