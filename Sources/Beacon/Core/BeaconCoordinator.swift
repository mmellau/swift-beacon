import SwiftUI
import UIKit

struct PresentationContext: Sendable {
    let identifiers: Set<String>
    let cutoutAnimation: Animation?
    let onInteraction: BeaconInteractionHandler?
    let focusRestoration: BeaconFocusRestoration
    let labelView: @MainActor () -> any View
}

@Observable
@MainActor
final class BeaconCoordinator {

    private(set) var registeredTargets: [String: BeaconRegion] = [:]
    private(set) var currentPresentation: PresentationContext?
    var style: BeaconStyle = .dimmed

    let windowManager: WindowManager

    var activeIdentifiers: Set<String> {
        currentPresentation?.identifiers ?? []
    }

    var activeRegions: [BeaconRegion] {
        activeIdentifiers.compactMap { registeredTargets[$0] }
            .filter { !$0.frame.isEmpty }
    }

    var isPresenting: Bool {
        currentPresentation != nil
    }

    var currentCutoutAnimation: Animation {
        currentPresentation?.cutoutAnimation ?? Beacon.animation.cutoutTransition
    }

    init(windowManager: WindowManager = .live) {
        self.windowManager = windowManager
    }

    func handleInteraction(_ interaction: BeaconInteraction) {
        guard let handler = currentPresentation?.onInteraction else {
            dismiss()
            return
        }
        handler(interaction)
    }

    func register(_ identifier: String, frame: CGRect, shape: BeaconShape, padding: CGFloat) {
        if registeredTargets[identifier] == nil {
            Beacon.log(.info, "Registering target: \(identifier)")
        }

        if frame.isEmpty {
            Beacon.log(.warning, "Registering '\(identifier)' with zero frame - may not be visible")
        }

        registeredTargets[identifier] = BeaconRegion(
            id: identifier,
            frame: frame,
            shape: shape,
            padding: padding
        )
    }

    func unregister(_ identifier: String) {
        Beacon.log(.info, "Unregistering target: \(identifier)")
        registeredTargets.removeValue(forKey: identifier)

        guard let presentation = currentPresentation,
              presentation.identifiers.contains(identifier) else {
            return
        }

        Beacon.log(.warning, "Active target '\(identifier)' disappeared")

        let remaining = presentation.identifiers.subtracting([identifier])
        if remaining.isEmpty {
            // If no active targets remain and no sequence is running, dismiss.
            // During sequences, targets may temporarily disappear during view re-renders,
            // so we let the sequence runner manage the overlay lifecycle.
            if !Beacon.Sequence.isRunning {
                Beacon.log(.info, "No active targets remain — dismissing")
                dismiss()
            }
        } else {
            currentPresentation = PresentationContext(
                identifiers: remaining,
                cutoutAnimation: presentation.cutoutAnimation,
                onInteraction: presentation.onInteraction,
                focusRestoration: presentation.focusRestoration,
                labelView: presentation.labelView
            )
        }
    }

    func present(
        _ identifiers: String...,
        onInteraction: BeaconInteractionHandler? = nil,
        focusRestoration: BeaconFocusRestoration = .highlighted,
        labelView: @escaping @MainActor () -> any View
    ) {
        present(
            Array(identifiers),
            onInteraction: onInteraction,
            focusRestoration: focusRestoration,
            labelView: labelView
        )
    }

    func present(
        _ identifiers: [String],
        onInteraction: BeaconInteractionHandler? = nil,
        focusRestoration: BeaconFocusRestoration = .highlighted,
        labelView: @escaping @MainActor () -> any View
    ) {
        if isPresenting {
            Beacon.log(.info, "Replacing active presentation")
            currentPresentation?.onInteraction?(.dismissed)
        }

        currentPresentation = PresentationContext(
            identifiers: Set(identifiers),
            cutoutAnimation: nil,
            onInteraction: onInteraction,
            focusRestoration: focusRestoration,
            labelView: labelView
        )

        windowManager.showIfNeeded()
        postAccessibilityScreenChange()
    }

    func dismiss() {
        let handler = currentPresentation?.onInteraction
        let focusRestoration = currentPresentation?.focusRestoration ?? .none

        currentPresentation = nil

        handler?(.dismissed)

        let delay: TimeInterval = 0.25
        windowManager.hide(delay)
        postAccessibilityFocusRestoration(focusRestoration, afterDelay: delay)
    }

    func updateActiveIdentifiers(
        _ identifiers: [String],
        cutoutAnimation: Animation?,
        labelView: @escaping @MainActor () -> any View
    ) {
        guard let presentation = currentPresentation else {
            currentPresentation = PresentationContext(
                identifiers: Set(identifiers),
                cutoutAnimation: cutoutAnimation,
                onInteraction: nil,
                focusRestoration: .highlighted,
                labelView: labelView
            )
            return
        }

        currentPresentation = PresentationContext(
            identifiers: Set(identifiers),
            cutoutAnimation: cutoutAnimation,
            onInteraction: presentation.onInteraction,
            focusRestoration: presentation.focusRestoration,
            labelView: labelView
        )
    }

    func setInteractionHandler(_ handler: BeaconInteractionHandler?) {
        guard let presentation = currentPresentation else {
            currentPresentation = PresentationContext(
                identifiers: [],
                cutoutAnimation: nil,
                onInteraction: handler,
                focusRestoration: .highlighted,
                labelView: { EmptyView() }
            )
            return
        }
        currentPresentation = PresentationContext(
            identifiers: presentation.identifiers,
            cutoutAnimation: presentation.cutoutAnimation,
            onInteraction: handler,
            focusRestoration: presentation.focusRestoration,
            labelView: presentation.labelView
        )
    }

    private func postAccessibilityScreenChange() {
        Task {
            try? await Task.sleep(for: .milliseconds(100))
            UIAccessibility.post(notification: .screenChanged, argument: nil)
        }
    }

    private func postAccessibilityFocusRestoration(
        _ focusRestoration: BeaconFocusRestoration,
        afterDelay delay: TimeInterval
    ) {
        guard focusRestoration != .none else { return }

        Task {
            try? await Task.sleep(for: .seconds(delay) + .milliseconds(100))
            UIAccessibility.post(notification: .screenChanged, argument: nil)
        }
    }
}
