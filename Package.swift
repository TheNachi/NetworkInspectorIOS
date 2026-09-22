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
        ),
        .library(
            name: "NetInspectorCore",
            targets: ["NetInspectorCore"]
        ),
        .library(
            name: "NetInspectorUI",
            targets: ["NetInspectorUI"]
        ),
        .library(
            name: "NetInspectorPlugins",
            targets: ["NetInspectorPlugins"]
        ),
        .library(
            name: "NetInspectorURLSession",
            targets: ["NetInspectorURLSession"]
        ),
        .library(
            name: "NetInspectorDiagnostics",
            targets: ["NetInspectorDiagnostics"]
        ),
        .library(
            name: "NetInspectorExporters",
            targets: ["NetInspectorExporters"]
        )
    ],

    targets: [

        // MARK: - Core

        .target(
            name: "NetInspectorCore"
        ),

        // MARK: - URLSession

        .target(
            name: "NetInspectorURLSession",
            dependencies: ["NetInspectorCore"]
        ),

        // MARK: - Diagnostics

        .target(
            name: "NetInspectorDiagnostics",
            dependencies: ["NetInspectorCore"]
        ),

        // MARK: - Exporters

        .target(
            name: "NetInspectorExporters",
            dependencies: ["NetInspectorCore"]
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
                "NetInspectorPlugins",
                "NetInspectorURLSession",
                "NetInspectorDiagnostics",
                "NetInspectorExporters"
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
        ),

        .testTarget(
            name: "NetInspectorPluginsTests",
            dependencies: [
                "NetInspectorPlugins"
            ]
        ),

        .testTarget(
            name: "NetworkInspectorTests",
            dependencies: [
                "NetworkInspector"
            ]
        )
    ]
)