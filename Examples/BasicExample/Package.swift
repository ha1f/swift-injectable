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
        .executableTarget(
            name: "BasicExample",
            dependencies: [
                .product(name: "SwiftInjectableMacros", package: "swift-injectable"),
                .product(name: "Mockable", package: "swift-mockable"),
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "BasicExampleTests",
            dependencies: [
                "BasicExample",
                .product(name: "Mockable", package: "swift-mockable"),
            ],
            path: "Tests"
        ),
    ],
    swiftLanguageModes: [.v6]
)
