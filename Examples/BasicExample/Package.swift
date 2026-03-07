// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "BasicExample",
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
            name: "ConsoleLogger",
            dependencies: ["Domain"],
            path: "Sources/ConsoleLogger"
        ),
        .target(
            name: "LiveAPIClient",
            dependencies: ["Domain"],
            path: "Sources/LiveAPIClient"
        ),
        .target(
            name: "Presentation",
            dependencies: [
                "Domain",
                .product(name: "SwiftInjectable", package: "swift-injectable"),
            ],
            path: "Sources/Presentation"
        ),
        .executableTarget(
            name: "App",
            dependencies: [
                "Domain",
                "ConsoleLogger",
                "LiveAPIClient",
                "Presentation",
                .product(name: "SwiftInjectable", package: "swift-injectable"),
            ],
            path: "Sources/App"
        ),
        .testTarget(
            name: "DomainTests",
            dependencies: [
                "Domain",
                .product(name: "Mockable", package: "swift-mockable"),
            ],
            path: "Tests/DomainTests"
        ),
        .testTarget(
            name: "PresentationTests",
            dependencies: [
                "Domain",
                "Presentation",
                .product(name: "SwiftInjectable", package: "swift-injectable"),
                .product(name: "Mockable", package: "swift-mockable"),
            ],
            path: "Tests/PresentationTests"
        ),
        .testTarget(
            name: "AppTests",
            dependencies: [
                "Domain",
                "ConsoleLogger",
                "LiveAPIClient",
                .product(name: "SwiftInjectable", package: "swift-injectable"),
                .product(name: "Mockable", package: "swift-mockable"),
            ],
            path: "Tests/AppTests"
        ),
    ],
    swiftLanguageModes: [.v6]
)
