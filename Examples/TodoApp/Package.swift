// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "TodoApp",
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
            name: "Data",
            dependencies: ["Domain"],
            path: "Sources/Data"
        ),
        .target(
            name: "Infrastructure",
            dependencies: ["Domain"],
            path: "Sources/Infrastructure"
        ),
        .target(
            name: "Presentation",
            dependencies: [
                "Domain",
                .product(name: "SwiftInjectable", package: "swift-injectable"),
                .product(name: "SwiftHooks", package: "swift-injectable"),
            ],
            path: "Sources/Presentation"
        ),
        .executableTarget(
            name: "App",
            dependencies: [
                "Domain",
                "Data",
                "Infrastructure",
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
            name: "DataTests",
            dependencies: [
                "Data",
                "Domain",
                .product(name: "Mockable", package: "swift-mockable"),
            ],
            path: "Tests/DataTests"
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
    ],
    swiftLanguageModes: [.v6]
)
