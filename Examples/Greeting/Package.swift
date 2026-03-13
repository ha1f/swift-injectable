// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Greeting",
    platforms: [
        .iOS(.v17),
        .macOS(.v15),
    ],
    dependencies: [
        .package(path: "../../"),
        .package(url: "https://github.com/yysskk/swift-mockable", from: "1.5.0"),
    ],
    targets: [
        .target(
            name: "Domain",
            dependencies: [
                .product(name: "Mockable", package: "swift-mockable"),
            ],
            path: "Sources/Domain"
        ),
        .target(
            name: "GreetingFeature",
            dependencies: [
                "Domain",
                .product(name: "SwiftInjectable", package: "swift-injectable"),
                .product(name: "SwiftHooks", package: "swift-injectable"),
            ],
            path: "Sources/Feature/GreetingFeature"
        ),
        .executableTarget(
            name: "App",
            dependencies: [
                "Domain",
                "GreetingFeature",
                .product(name: "SwiftInjectable", package: "swift-injectable"),
            ],
            path: "Sources/App"
        ),
        .testTarget(
            name: "GreetingFeatureTests",
            dependencies: [
                "Domain",
                "GreetingFeature",
                .product(name: "SwiftInjectable", package: "swift-injectable"),
                .product(name: "Mockable", package: "swift-mockable"),
            ],
            path: "Tests/GreetingFeatureTests"
        ),
    ],
    swiftLanguageModes: [.v6]
)
