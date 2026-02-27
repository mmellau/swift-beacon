import SwiftUI
import UIKit

struct WindowManager: Sendable {
    var showIfNeeded: @MainActor @Sendable () -> Void
    var hide: @MainActor @Sendable (_ afterDelay: TimeInterval) -> Void
}

extension WindowManager {

    @MainActor
    static let live: WindowManager = {
        let manager = BeaconWindowManager()
        return WindowManager(
            showIfNeeded: { manager.showIfNeeded() },
            hide: { delay in manager.hide(afterDelay: delay) }
        )
    }()

    static let mock = WindowManager(
        showIfNeeded: { },
        hide: { _ in }
    )

    static func spy(
        onShow: @escaping @MainActor @Sendable () -> Void = { },
        onHide: @escaping @MainActor @Sendable (TimeInterval) -> Void = { _ in }
    ) -> WindowManager {
        WindowManager(showIfNeeded: onShow, hide: onHide)
    }
}

@MainActor
final class BeaconWindowManager {

    private var hostWindow: PassThroughWindow?
    private var hostingController: UIHostingController<BeaconWindowOverlay>?

    init() {}

    func showIfNeeded() {
        guard hostWindow == nil else { return }
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }

        Beacon.log(.info, "Creating overlay window")
        let window = PassThroughWindow(windowScene: scene)
        hostWindow = window

        window.backgroundColor = .clear
        window.windowLevel = .alert + 1  // Above sheets, alerts, etc.

        let overlayView = BeaconWindowOverlay()
        let controller = UIHostingController(rootView: overlayView)
        controller.view.backgroundColor = .clear
        hostingController = controller

        window.rootViewController = controller
        window.isHidden = false
    }

    func hide(afterDelay delay: TimeInterval) {
        Beacon.log(.info, "Hiding overlay window")

        if delay > 0 {
            Task { [weak self] in
                try? await Task.sleep(for: .seconds(delay))
                self?.hideImmediately()
            }
        } else {
            hideImmediately()
        }
    }

    private func hideImmediately() {
        hostWindow?.isHidden = true
        hostWindow?.rootViewController = nil
        hostWindow = nil
        hostingController = nil
    }
}

private final class PassThroughWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard Beacon.isPresenting else { return nil }
        return super.hitTest(point, with: event)
    }
}

struct BeaconWindowOverlay: View {
    private let coordinator = Beacon.coordinator

    var body: some View {
        let regions = coordinator.activeRegions
        if coordinator.isPresenting && !regions.isEmpty {
            BeaconCanvas(
                regions: regions,
                style: coordinator.style,
                animation: coordinator.currentCutoutAnimation,
                coordinator: coordinator
            )
            .transition(.asymmetric(
                insertion: .opacity.animation(Beacon.animation.overlayAppear),
                removal: .opacity.animation(Beacon.animation.overlayDisappear)
            ))
        }
    }
}

struct BeaconCanvas: View {
    let regions: [BeaconRegion]
    let style: BeaconStyle
    let animation: Animation
    let coordinator: BeaconCoordinator

    var body: some View {
        ZStack {
            style.color.opacity(style.opacity)
                .onTapGesture {
                    coordinator.handleInteraction(.tappedOutside)
                }
                .accessibilityLabel("Dismiss spotlight")
                .accessibilityHint("Double tap to dismiss")
                .accessibilityAddTraits(.isButton)

            if regions.count == 1, let region = regions.first {
                AnimatedCutout(
                    frame: region.paddedFrame,
                    cornerRadius: region.cornerRadius,
                    regionId: region.id,
                    animation: animation,
                    coordinator: coordinator
                )
            } else {
                ForEach(regions) { region in
                    StaticCutout(region: region, coordinator: coordinator)
                }
            }

            if let labelView = coordinator.currentPresentation?.labelView {
                let allBounds = regions.reduce(CGRect.null) { result, item in
                    result.union(item.paddedFrame)
                }

                GeometryReader { geo in
                    let unitPoint = UnitPoint(
                        x: allBounds.midX / geo.size.width,
                        y: allBounds.midY / geo.size.height
                    )

                    VStack {
                        let isTop = unitPoint.y < 0.5
                        let isLeading = unitPoint.x < 0.7

                        Spacer().frame(height: isTop ? max(0, allBounds.maxY) : nil)

                        HStack {
                            if !isLeading {
                                Spacer()
                            }

                            AnyView(labelView())
                                .multilineTextAlignment(isLeading ? .leading : .trailing)
                                .foregroundStyle(style.textColor)

                            if isLeading {
                                Spacer()
                            }
                        }
                        .padding(.vertical)
                        .allowsHitTesting(false)
                        .accessibilityRespondsToUserInteraction(false)
                        .safeAreaPadding(isLeading ? .trailing : .leading)
                        .padding(
                            isLeading ? .leading : .trailing,
                            isLeading ? allBounds.minX : geo.size.width - allBounds.maxX,
                        )

                        Spacer().frame(height: isTop ? nil : max(0, geo.size.height - allBounds.minY))
                    }.frame(width: geo.size.width)
                }.ignoresSafeArea()
            }
        }
        .compositingGroup()
        .ignoresSafeArea()
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape) {
            Beacon.dismiss()
        }
    }
}

private struct AnimatedCutout: View {
    let frame: CGRect
    let cornerRadius: CGFloat
    let regionId: String
    let animation: Animation
    let coordinator: BeaconCoordinator

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(.white)
            .frame(width: frame.width, height: frame.height)
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
            .onTapGesture {
                coordinator.handleInteraction(.tappedRegion(regionId))
            }
            .position(x: frame.midX, y: frame.midY)
            .blendMode(.destinationOut)
            .animation(animation, value: frame)
            .animation(animation, value: cornerRadius)
            .accessibilityLabel("Highlighted element")
            .accessibilityHint("Double tap to continue")
            .accessibilityAddTraits(.isButton)
    }
}

private struct StaticCutout: View {
    let region: BeaconRegion
    let coordinator: BeaconCoordinator

    var body: some View {
        RoundedRectangle(cornerRadius: region.cornerRadius)
            .fill(.white)
            .frame(width: region.paddedFrame.width, height: region.paddedFrame.height)
            .contentShape(RoundedRectangle(cornerRadius: region.cornerRadius))
            .onTapGesture {
                coordinator.handleInteraction(.tappedRegion(region.id))
            }
            .position(x: region.paddedFrame.midX, y: region.paddedFrame.midY)
            .blendMode(.destinationOut)
            .accessibilityLabel("Highlighted element")
            .accessibilityHint("Double tap to continue")
            .accessibilityAddTraits(.isButton)
    }
}
