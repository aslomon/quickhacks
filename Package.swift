// swift-tools-version:5.10
import PackageDescription

let package = Package(
  name: "QuickHacks",
  platforms: [.macOS(.v14)],
  targets: [
    .executableTarget(
      name: "QuickHacks",
      path: "Sources/QuickHacks"
    ),
    .testTarget(
      name: "QuickHacksTests",
      dependencies: ["QuickHacks"],
      path: "Tests/QuickHacksTests"
    ),
  ]
)
