// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let binaryTarget: Target
let maplibreSwiftUIDSLPackage: Package.Dependency
let useLocalFramework = false
let useLocalMapLibreSwiftUIDSL = false

if useLocalFramework {
    binaryTarget = .binaryTarget(
        name: "FerrostarCoreRS",
        // IMPORTANT: Swift packages importing this locally will not be able to
        // import Ferrostar core unless you specify this as a relative path!
        path: "./common/target/ios/libferrostar-rs.xcframework"
    )
} else {
    let releaseTag = "0.0.30"
    let releaseChecksum = "b73c595af37be242c36f0520501f81b4c871a797c2bae124da6bd0e4137bd6a0"
    binaryTarget = .binaryTarget(
        name: "FerrostarCoreRS",
        url: "https://github.com/stadiamaps/ferrostar/releases/download/\(releaseTag)/libferrostar-rs.xcframework.zip",
        checksum: releaseChecksum
    )
}

if useLocalMapLibreSwiftUIDSL {
    maplibreSwiftUIDSLPackage = .package(path: "../maplibre-swiftui-dsl-playground")
} else {
    maplibreSwiftUIDSLPackage = .package(
        url: "https://github.com/stadiamaps/maplibre-swiftui-dsl-playground",
        from: "0.0.15"
    )
}

let package = Package(
    name: "FerrostarCore",
    platforms: [
        .iOS(.v15),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "FerrostarCore",
            targets: ["FerrostarCore", "FerrostarCoreFFI"]
        ),
        .library(
            name: "FerrostarMapLibreUI",
            targets: ["FerrostarMapLibreUI",
                      "FerrostarSwiftUI"] // TODO: Remove FerrostarSwiftUI from FerrostarMapLibreUI once we can fix the demo app swift package config (broken in Xcode 15.3)
        ),
        .library(
            name: "FerrostarSwiftUI",
            targets: ["FerrostarSwiftUI"]
        ),
    ],
    dependencies: [
        maplibreSwiftUIDSLPackage,
        .package(
            url: "https://github.com/pointfreeco/swift-snapshot-testing",
            from: "1.15.0"
        ),
    ],
    targets: [
        binaryTarget,
        .target(
            name: "FerrostarCore",
            dependencies: [.target(name: "FerrostarCoreFFI")],
            path: "apple/Sources/FerrostarCore"
        ),
        .target(
            name: "FerrostarMapLibreUI",
            dependencies: [
                .target(name: "FerrostarCore"),
                .product(name: "MapLibreSwiftDSL", package: "maplibre-swiftui-dsl-playground"),
                .product(name: "MapLibreSwiftUI", package: "maplibre-swiftui-dsl-playground"),
            ],
            path: "apple/Sources/FerrostarMapLibreUI"
        ),
        .target(
            name: "FerrostarSwiftUI",
            dependencies: [
                .target(name: "FerrostarCore"),
            ],
            path: "apple/Sources/FerrostarSwiftUI",
            resources: [
                .process("Resources"),
            ]
        ),
        .target(
            name: "FerrostarCoreFFI",
            dependencies: [.target(name: "FerrostarCoreRS")],
            path: "apple/Sources/UniFFI"
        ),

        // MARK: Testing

        .testTarget(
            name: "FerrostarCoreTests",
            dependencies: [
                "FerrostarCore",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ],
            path: "apple/Tests/FerrostarCoreTests"
        ),
        .testTarget(
            name: "FerrostarSwiftUITests",
            dependencies: [
                "FerrostarCore",
                "FerrostarSwiftUI",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ],
            path: "apple/Tests/FerrostarSwiftUITests"
        ),
    ]
)
