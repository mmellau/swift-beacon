// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Beacon",
    platforms: [.iOS("18.4")],
    products: [
        .library(
            name: "Beacon",
            targets: ["Beacon"]
        )
    ],
    targets: [
        .target(
            name: "Beacon",
            swiftSettings: [
                .enableUpcomingFeature("InferIsolatedConformances"),
                .enableUpcomingFeature("NonisolatedNonsendingByDefault")
            ]
        ),
        .testTarget(
            name: "BeaconTests",
            dependencies: ["Beacon"],
            swiftSettings: [
                .enableUpcomingFeature("InferIsolatedConformances"),
                .enableUpcomingFeature("NonisolatedNonsendingByDefault")
            ]
        )
    ]
)
