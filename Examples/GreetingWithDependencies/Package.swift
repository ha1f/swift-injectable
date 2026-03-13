// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "GreetingWithDependencies",
    platforms: [
        .iOS(.v17),
        .macOS(.v15),
    ],
    dependencies: [
        .package(path: "../../"),
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.11.0"),
    ],
    targets: [
        .target(
            name: "Domain",
            dependencies: [
                .product(name: "Dependencies", package: "swift-dependencies"),
            ],
            path: "Sources/Domain"
        ),
        .target(
            name: "GreetingFeature",
            dependencies: [
                "Domain",
                .product(name: "SwiftHooks", package: "swift-injectable"),
                .product(name: "Dependencies", package: "swift-dependencies"),
            ],
            path: "Sources/Feature/GreetingFeature"
        ),
        .executableTarget(
            name: "App",
            dependencies: [
                "Domain",
                "GreetingFeature",
            ],
            path: "Sources/App"
        ),
        .testTarget(
            name: "GreetingFeatureTests",
            dependencies: [
                "Domain",
                "GreetingFeature",
                .product(name: "Dependencies", package: "swift-dependencies"),
            ],
            path: "Tests/GreetingFeatureTests"
        ),
    ],
    swiftLanguageModes: [.v6]
)
