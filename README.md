<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="Assets/beacon-icon-dark.svg">
    <source media="(prefers-color-scheme: light)" srcset="Assets/beacon-icon.svg">
    <img alt="Beacon" src="Assets/beacon-icon.svg" width="80" height="80">
  </picture>
</p>

<h1 align="center">Beacon</h1>

<p align="center">
  <strong>SwiftUI spotlight overlay framework</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/iOS-18.4+-blue.svg" alt="iOS 18.4+">
  <img src="https://img.shields.io/badge/Swift-6.2-orange.svg" alt="Swift 6.2">
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="MIT License">
</p>

<p align="center">
  <video src="Assets/manual-demo.mp4" width="300" autoplay loop muted playsinline></video>
  &nbsp;&nbsp;
  <video src="Assets/auto-demo.mp4" width="300" autoplay loop muted playsinline></video>
</p>
<p align="center">
  <sub>Step-by-step spotlight tour · Auto-advancing tutorial</sub>
</p>

## Features

- Single-line spotlight presentation
- Declarative sequence builder with step navigation
- Multiple spotlight shapes
- Configurable overlay style and animations
- Works across sheets, popovers, and navigation stacks
- Async/await support
- Optional os.Logger integration
- VoiceOver support

## Installation

### Swift Package Manager

Add Beacon to your project via Xcode:

1. File > Add Package Dependencies
2. Enter: `https://github.com/mmellau/swift-beacon`
3. Select version and add to your target

Or add to `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/mmellau/swift-beacon", from: "0.1.0")
]
```

## Quick Start

### 1. Mark targets

```swift
import Beacon

Image(systemName: "star")
    .beaconTarget("star")
```

### 2. Present spotlight

```swift
// Fire-and-forget
Beacon.present("star")

// Multiple targets
Beacon.present("inbox", "compose", "settings")

// When you need the result
let result = await Beacon.presentAsync("star")
switch result {
case .tappedOutside: print("User dismissed")
case .tappedRegion(let id): print("User tapped: \(id)")
case .dismissed: print("Dismissed externally")
}
```

### 3. Dismiss

```swift
Beacon.dismiss()
```

## Sequences

Chain steps into guided tours:

```swift
// Fire-and-forget
Beacon.Sequence.run {
    BeaconStep(targets: ["profile"])
    BeaconStep(targets: ["search"])
    BeaconStep(targets: ["settings"])
}

// When you need to await completion
await Beacon.Sequence.runAsync {
    BeaconStep(targets: ["profile"])
    BeaconStep(targets: ["settings"])
}
print("Onboarding complete!")
```

## Configuration

### Style

```swift
// Built-in presets
Beacon.style = .dimmed  // Default (55% opacity)
Beacon.style = .light   // 30% opacity
Beacon.style = .dark    // 75% opacity

// Custom
Beacon.style = BeaconStyle(color: .blue, opacity: 0.6)
```

### Shapes

```swift
Image(systemName: "star")
    .beaconTarget("star")  // Default: circle

Button("Submit")
    .beaconTarget("submit", shape: .capsule)

RoundedRectangle(cornerRadius: 12)
    .beaconTarget("card", shape: .rectangle(cornerRadius: 12))
```

## Usage Example

```swift
func handleFirstLaunch() async {
    let isFirstLaunch = await checkFirstLaunch()
    if isFirstLaunch {
        await Beacon.Sequence.runAsync {
            BeaconStep(targets: ["welcome"])
            BeaconStep(targets: ["main_feature"])
        }
        await markOnboardingComplete()
    }
}
```

## Requirements

- iOS 18.4+
- Swift 6.2+
- Xcode 26.0+

## Demo App

See [BeaconDemo](Examples/BeaconDemo) for an example app.

## License

MIT License. See [LICENSE](LICENSE) for details.
