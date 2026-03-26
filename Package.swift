// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "WebmuxClient",
  platforms: [.macOS(.v15)],
  targets: [
    .executableTarget(
      name: "WebmuxClient",
      path: "Sources/WebmuxClient",
      resources: [
        .process("Resources")
      ]
    )
  ]
)
