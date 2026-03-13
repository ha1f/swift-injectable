// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Counter",
    platforms: [
        .iOS(.v17),
        .macOS(.v15),
    ],
    dependencies: [
        .package(path: "../../"),
    ],
    targets: [
        .target(
            name: "CounterFeature",
            dependencies: [
                .product(name: "SwiftHooks", package: "swift-injectable"),
            ],
            path: "Sources/Feature/CounterFeature"
        ),
        .executableTarget(
            name: "App",
            dependencies: ["CounterFeature"],
            path: "Sources/App"
        ),
        .testTarget(
            name: "CounterFeatureTests",
            dependencies: ["CounterFeature"],
            path: "Tests/CounterFeatureTests"
        ),
    ],
    swiftLanguageModes: [.v6]
)
