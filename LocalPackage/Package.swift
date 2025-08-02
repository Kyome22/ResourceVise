// swift-tools-version: 6.1

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny"),
]

let package = Package(
    name: "LocalPackage",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "DataSource",
            targets: ["DataSource"]
        ),
        .library(
            name: "Model",
            targets: ["Model"]
        ),
        .library(
            name: "UserInterface",
            targets: ["UserInterface"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", exact: "1.6.1"),
        .package(url: "https://github.com/Kyome22/WebPEncoder.git", exact: "0.1.1"),
    ],
    targets: [
        .target(
            name: "DataSource",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "Model",
            dependencies: [
                "DataSource",
                .product(name: "Logging", package: "swift-log"),
                .product(name: "WebPEncoder", package: "WebPEncoder"),
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "UserInterface",
            dependencies: [
                "Model",
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "ModelTests",
            dependencies: [
                "DataSource",
                "Model",
            ],
            swiftSettings: swiftSettings
        ),
    ]
)
