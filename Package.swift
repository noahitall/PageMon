// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PageMon",
    platforms: [
        .iOS(.v16), // Adjust this to match your deployment target
        .macOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "PageMon",
            targets: ["PageMon"]),
    ],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "PageMon",
            dependencies: ["SwiftSoup"]),
        .testTarget(
            name: "PageMonTests",
            dependencies: ["PageMon"]
        ),
    ]
)
