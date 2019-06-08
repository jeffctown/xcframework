// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "xcframework",
    products: [
        .library(name: "XCFrameworkKit", targets: ["XCFrameworkKit"]),
        .executable(name: "xcframework", targets: ["xcframework"])
    ],
    dependencies: [
        .package(url: "https://github.com/AlwaysRightInstitute/Shell", from: "0.1.4"),
        .package(url: "https://github.com/Carthage/Commandant", from: "0.17.0")
    ],
    targets: [
        .target(
            name: "xcframework",
            dependencies: ["XCFrameworkKit", "Commandant"]),
        .target(
            name: "XCFrameworkKit",
            dependencies: ["Shell"]),
        .testTarget(
            name: "XCFrameworkKitTests",
            dependencies: ["XCFrameworkKit"]),
    ]
)
