// swift-tools-version: 5.9
import PackageDescription

/// Shared native code for the knowitwhere extensions (SRS Phase 4).
///
/// - KnowItWhereCore: reads the App Group shared cache, Siri matching, voice copy
/// - KnowItWhereWidgetUI: the home-screen widget (FR4)
/// - KnowItWhereIntents: the Siri "find" App Intent (FR5)
let package = Package(
  name: "KnowItWhereKit",
  platforms: [.iOS(.v17), .macOS(.v14)],
  products: [
    .library(name: "KnowItWhereCore", targets: ["KnowItWhereCore"]),
    .library(name: "KnowItWhereWidgetUI", targets: ["KnowItWhereWidgetUI"]),
    .library(name: "KnowItWhereIntents", targets: ["KnowItWhereIntents"]),
  ],
  targets: [
    .target(name: "KnowItWhereCore"),
    .target(name: "KnowItWhereWidgetUI", dependencies: ["KnowItWhereCore"]),
    .target(name: "KnowItWhereIntents", dependencies: ["KnowItWhereCore"]),
    .testTarget(name: "KnowItWhereCoreTests", dependencies: ["KnowItWhereCore"]),
  ]
)
