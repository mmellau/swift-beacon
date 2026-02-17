import SwiftUI
import Beacon
import os

struct SettingsView: View {
    @State private var selectedStyle: StyleOption = .dimmed
    @State private var selectedAnimation: AnimationOption = .default
    @State private var loggerEnabled = false
    @State private var validationResult: String?

    private let logger = Logger(subsystem: "com.matemellau.BeaconDemo", category: "beacon")
    private let demoState = DemoState.shared

    var body: some View {
        NavigationStack {
            List {
                AppearanceSection(
                    selectedStyle: $selectedStyle,
                    selectedAnimation: $selectedAnimation
                )
                DemoSection(onReset: { withAnimation { demoState.reset() } })
                DebugSection(
                    loggerEnabled: $loggerEnabled,
                    validationResult: $validationResult,
                    logger: logger
                )
            }
            .navigationTitle("Settings")
        }
    }
}

private struct AppearanceSection: View {
    @Binding var selectedStyle: StyleOption
    @Binding var selectedAnimation: AnimationOption

    var body: some View {
        Section {
            Picker("Overlay Style", selection: $selectedStyle) {
                ForEach(StyleOption.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .onChange(of: selectedStyle) { _, newValue in
                Beacon.style = newValue.beaconStyle
            }

            Picker("Animation", selection: $selectedAnimation) {
                ForEach(AnimationOption.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .onChange(of: selectedAnimation) { _, newValue in
                Beacon.animation = newValue.beaconAnimation
            }

            Button("Preview Spotlight") {
                Beacon.present("settings-preview")
            }
            .beaconTarget("settings-preview")
        } header: {
            Text("Appearance")
        } footer: {
            Text("Changes apply to all spotlights across the app.")
        }
    }
}

private struct DemoSection: View {
    let onReset: () -> Void

    var body: some View {
        Section {
            Button("Reset Demo State") {
                onReset()
            }
        } header: {
            Text("Demo")
        } footer: {
            Text("Resets onboarding and tutorial completion. Cards will reappear on Tasks tab.")
        }
    }
}

private struct DebugSection: View {
    @Binding var loggerEnabled: Bool
    @Binding var validationResult: String?
    let logger: Logger

    var body: some View {
        Section {
            Toggle("Enable Logging", isOn: $loggerEnabled)
                .onChange(of: loggerEnabled) { _, enabled in
                    Beacon.logger = enabled ? logger : nil
                }

            DisclosureGroup("Registered Targets (\(Beacon.registeredTargets.count))") {
                if Beacon.registeredTargets.isEmpty {
                    Text("No targets registered")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(Beacon.registeredTargets.keys.sorted()), id: \.self) { id in
                        TargetRow(id: id)
                    }
                }
            }

            Button("Validate Onboarding Sequence") {
                validateOnboardingSequence()
            }

            if let result = validationResult {
                Text(result)
                    .font(.caption)
                    .foregroundStyle(result.contains("valid") ? .green : .orange)
            }
        } header: {
            Text("Debug")
        } footer: {
            Text("Logger output appears in Console.app or Xcode console.")
        }
    }

    private func validateOnboardingSequence() {
        let sequence = BeaconSequence {
            BeaconStep(targets: ["add-task"])
            BeaconStep(targets: ["title-field"])
            BeaconStep(targets: ["due-toggle"])
            BeaconStep(targets: ["add-button"])
            BeaconStep(targets: ["task-checkbox"])
        }

        let result = Beacon.Sequence.validate(sequence)
        if result.hasInvalidTargets {
            validationResult = "Missing: \(result.allInvalidTargets.joined(separator: ", "))"
        } else {
            validationResult = "All targets valid"
        }
    }
}

private struct TargetRow: View {
    let id: String

    var body: some View {
        HStack {
            Text(id)
                .font(.caption.monospaced())
            Spacer()
            Button("Show") { Beacon.present(id) }
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
    }
}

enum StyleOption: String, CaseIterable, Identifiable {
    case dimmed = "Dimmed"
    case light = "Light"
    case dark = "Dark"

    var id: String { rawValue }

    var beaconStyle: BeaconStyle {
        switch self {
        case .dimmed: .dimmed
        case .light: .light
        case .dark: .dark
        }
    }
}

enum AnimationOption: String, CaseIterable, Identifiable {
    case `default` = "Default"
    case bouncy = "Bouncy"
    case slow = "Slow"

    var id: String { rawValue }

    var beaconAnimation: BeaconAnimation {
        switch self {
        case .default:
            .default
        case .bouncy:
            BeaconAnimation(
                overlayAppear: .bouncy,
                overlayDisappear: .bouncy,
                cutoutTransition: .bouncy
            )
        case .slow:
            BeaconAnimation(
                overlayAppear: .easeOut(duration: 0.8),
                overlayDisappear: .easeIn(duration: 0.5),
                cutoutTransition: .easeInOut(duration: 0.6)
            )
        }
    }
}

#Preview {
    SettingsView()
}
