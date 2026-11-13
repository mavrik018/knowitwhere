// swift-tools-version: 5.9
import PackageDescription

/// Shared native code for the knowitwhere extensions (SRS Phase 4).
///
/// - KnowItWhereCore: reads the App Group shared cache, Siri matching, voice copy
/// - KnowItWhereWidgetUI: the home-screen widget (FR4)
///
/// The Siri App Intents themselves live in the app target
/// (ios/Runner/SiriIntents.swift): App Store builds don't register intents
/// that come from a package.
let package = Package(
  name: "KnowItWhereKit",
  platforms: [.iOS(.v17), .macOS(.v14)],
  products: [
    .library(name: "KnowItWhereCore", targets: ["KnowItWhereCore"]),
    .library(name: "KnowItWhereWidgetUI", targets: ["KnowItWhereWidgetUI"]),
  ],
  targets: [
    .target(name: "KnowItWhereCore"),
    .target(
      name: "KnowItWhereWidgetUI", dependencies: ["KnowItWhereCore"],
      resources: [.process("Resources")]),
    .testTarget(name: "KnowItWhereCoreTests", dependencies: ["KnowItWhereCore"]),
    .testTarget(name: "KnowItWhereWidgetUITests", dependencies: ["KnowItWhereWidgetUI"]),
  ]
)
