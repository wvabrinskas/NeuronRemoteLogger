// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NeuronRemoteLogger",
    platforms: [.macOS(.v11)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "NeuronRemoteLogger",
            targets: ["NeuronRemoteLogger"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
      .package(url: "https://github.com/pvieito/PythonKit.git", from: "0.3.1"),
      .package(url: "https://github.com/wvabrinskas/Logger.git", from: "1.0.6")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "NeuronRemoteLogger",
            dependencies: ["PythonKit", "Logger"]),
        .testTarget(
            name: "NeuronRemoteLoggerTests",
            dependencies: ["NeuronRemoteLogger"]),
    ]
)
