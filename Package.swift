// swift-tools-version: 6.0

import CompilerPluginSupport
import PackageDescription

let package = Package(
  name: "swift-injectable",
  platforms: [
    .iOS(.v17),
    .macOS(.v14),
    .tvOS(.v17),
    .watchOS(.v10),
  ],
  products: [
    .library(
      name: "SwiftInjectable",
      targets: ["SwiftInjectable"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/swiftlang/swift-syntax", "509.0.0"..<"603.0.0"),
  ],
  targets: [
    .target(
      name: "SwiftInjectable",
      dependencies: ["SwiftInjectableMacrosPlugin"]
    ),
    .macro(
      name: "SwiftInjectableMacrosPlugin",
      dependencies: [
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
      ]
    ),
    .testTarget(
      name: "SwiftInjectableTests",
      dependencies: [
        "SwiftInjectable",
        "SwiftInjectableMacrosPlugin",
        .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
      ]
    ),
  ],
  swiftLanguageModes: [.v6]
)
