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
    .library(
      name: "SwiftInjectableMacros",
      targets: ["SwiftInjectableMacros"]
    ),
    .library(
      name: "SwiftInjectableSwiftUI",
      targets: ["SwiftInjectableSwiftUI"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/swiftlang/swift-syntax", "509.0.0"..<"603.0.0"),
  ],
  targets: [
    .target(
      name: "SwiftInjectable"
    ),
    .target(
      name: "SwiftInjectableSwiftUI",
      dependencies: ["SwiftInjectable"]
    ),
    .target(
      name: "SwiftInjectableMacros",
      dependencies: ["SwiftInjectable", "SwiftInjectableMacrosPlugin"]
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
      dependencies: ["SwiftInjectable"]
    ),
    .testTarget(
      name: "SwiftInjectableSwiftUITests",
      dependencies: ["SwiftInjectable", "SwiftInjectableSwiftUI"]
    ),
    .testTarget(
      name: "SwiftInjectableMacrosPluginTests",
      dependencies: [
        "SwiftInjectable",
        "SwiftInjectableMacros",
        "SwiftInjectableMacrosPlugin",
        .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
      ]
    ),
  ],
  swiftLanguageModes: [.v6]
)
