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
            name: "TodoListFeature",
            dependencies: [
                "Domain",
                "TodoDetailFeature",
                "TodoFormFeature",
                .product(name: "SwiftInjectable", package: "swift-injectable"),
                .product(name: "SwiftHooks", package: "swift-injectable"),
            ],
            path: "Sources/TodoListFeature"
        ),
        .target(
            name: "TodoDetailFeature",
            dependencies: [
                "Domain",
            ],
            path: "Sources/TodoDetailFeature"
        ),
        .target(
            name: "TodoFormFeature",
            dependencies: [
                "Domain",
                .product(name: "SwiftHooks", package: "swift-injectable"),
            ],
            path: "Sources/TodoFormFeature"
        ),
        .target(
            name: "TodoStatsFeature",
            dependencies: [
                "Domain",
                "TodoListFeature",
                .product(name: "SwiftInjectable", package: "swift-injectable"),
                .product(name: "SwiftHooks", package: "swift-injectable"),
            ],
            path: "Sources/TodoStatsFeature"
        ),
        .executableTarget(
            name: "App",
            dependencies: [
                "Domain",
                "Data",
                "Infrastructure",
                "TodoListFeature",
                "TodoStatsFeature",
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
            name: "TodoListFeatureTests",
            dependencies: [
                "Domain",
                "TodoListFeature",
                .product(name: "SwiftInjectable", package: "swift-injectable"),
                .product(name: "Mockable", package: "swift-mockable"),
            ],
            path: "Tests/TodoListFeatureTests"
        ),
        .testTarget(
            name: "TodoFormFeatureTests",
            dependencies: [
                "TodoFormFeature",
            ],
            path: "Tests/TodoFormFeatureTests"
        ),
        .testTarget(
            name: "TodoStatsFeatureTests",
            dependencies: [
                "Domain",
                "TodoStatsFeature",
                .product(name: "SwiftInjectable", package: "swift-injectable"),
                .product(name: "Mockable", package: "swift-mockable"),
            ],
            path: "Tests/TodoStatsFeatureTests"
        ),
    ],
    swiftLanguageModes: [.v6]
)
