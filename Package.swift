// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NetworkInspector",

    platforms: [
        .iOS(.v16)
    ],

    products: [
        .library(
            name: "NetworkInspector",
            targets: [
                "NetworkInspector"
            ]
        )
    ],

    targets: [

        // MARK: - Core

        .target(
            name: "NetInspectorCore"
        ),

        // MARK: - UI

        .target(
            name: "NetInspectorUI",
            dependencies: [
                "NetInspectorCore"
            ]
        ),

        // MARK: - Plugins

        .target(
            name: "NetInspectorPlugins",
            dependencies: [
                "NetInspectorCore"
            ]
        ),

        // MARK: - Public SDK

        .target(
            name: "NetworkInspector",
            dependencies: [
                "NetInspectorCore",
                "NetInspectorUI",
                "NetInspectorPlugins"
            ]
        ),

        // MARK: - Tests

        .testTarget(
            name: "NetInspectorCoreTests",
            dependencies: [
                "NetInspectorCore"
            ]
        ),

        .testTarget(
            name: "NetInspectorUITests",
            dependencies: [
                "NetInspectorUI"
            ]
        )
    ]
)
