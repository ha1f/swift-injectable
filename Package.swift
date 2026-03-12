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
      name: "SwiftHooks",
      targets: ["SwiftHooks"]
    ),
    .library(
      name: "SwiftHooksQuery",
      targets: ["SwiftHooksQuery"]
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
    .target(
      name: "SwiftHooks",
      dependencies: ["SwiftHooksMacrosPlugin"]
    ),
    .macro(
      name: "SwiftHooksMacrosPlugin",
      dependencies: [
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
      ]
    ),
    .testTarget(
      name: "SwiftHooksTests",
      dependencies: [
        "SwiftHooks",
        "SwiftHooksMacrosPlugin",
        .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
      ]
    ),
    .target(
      name: "SwiftHooksQuery",
      dependencies: ["SwiftInjectable"]
    ),
    .testTarget(
      name: "SwiftHooksQueryTests",
      dependencies: [
        "SwiftHooksQuery",
        "SwiftInjectable",
      ]
    ),
  ],
  swiftLanguageModes: [.v6]
)
