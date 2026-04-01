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
  <a href="https://swiftpackageindex.com/mmellau/swift-beacon"><img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmmellau%2Fswift-beacon%2Fbadge%3Ftype%3Dswift-versions" alt="Swift versions"></a>
  <a href="https://swiftpackageindex.com/mmellau/swift-beacon"><img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmmellau%2Fswift-beacon%2Fbadge%3Ftype%3Dplatforms" alt="Platforms"></a>
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="MIT License">
</p>

<table align="center">
  <tr>
    <td align="center"><strong>Step-by-step tour</strong></td>
    <td align="center"><strong>Auto-advancing tutorial</strong></td>
  </tr>
  <tr>
    <td>

https://github.com/user-attachments/assets/2d85fa57-fff0-4274-9ff9-940abe1ac244

</td>
    <td>

https://github.com/user-attachments/assets/d6e2800a-2c51-46a8-b49d-9343881b0557

</td>
  </tr>
</table>

## Features

- Single-line spotlight presentation
- Declarative sequence builder with step navigation
- Tooltip/accessory views on cutouts with flexible positioning
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

## Tooltips

Attach custom views to spotlight cutouts:

### Simple tooltip

```swift
Beacon.Sequence.run {
    BeaconStep(targets: [
        BeaconTarget("star", alignment: .top) {
            Text("Tap to favorite")
        }
    ])
    BeaconStep(targets: ["settings"])  // no tooltip
}
```

### Per-target tooltips

Use `BeaconTarget` for per-cutout configuration:

```swift
Beacon.present(
    BeaconTarget("inbox", alignment: .top) {
        Label("3 new messages", systemImage: "envelope")
    },
    BeaconTarget("compose", alignment: .bottom) {
        Text("Write a new message")
    },
    "settings"  // no tooltip
)
```

### Positioning

Tooltips use SwiftUI's native `Alignment` (`.top`, `.bottom`, `.leading`, `.trailing`, and all 9 built-in positions). Fine-tune with `offset`:

```swift
BeaconStep(targets: [
    BeaconTarget("star", alignment: .top, offset: CGSize(width: 0, height: -8)) {
        Text("Tap to favorite")
    }
])
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
