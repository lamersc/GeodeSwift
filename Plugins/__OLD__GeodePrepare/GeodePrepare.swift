// handles building the geode-sdk with a makefile that can then be linked to swift

import Foundation
import PackagePlugin

enum GeodePrepareError: Error {
    case geodeSDKMissing(_ msg: String)
    case missingPermissions(_ msg: String)
}

@main
struct GeodePrepare: CommandPlugin {
    let fileManager = FileManager.default
    let dummyCMakeName = "CMakeLists.txt"

    func performCommand(context: PackagePlugin.PluginContext, arguments: [String]) throws {
        let pluginRootURL = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        let packageRootURL = context.package.directoryURL
        let toolURLs = [
            "git": try context.tool(named: "git").url,
            "cmake": try context.tool(named: "cmake").url,
            "geode": try context.tool(named: "geode").url,
        ]

        guard let geodeSDKPath = ProcessInfo.processInfo.environment["GEODE_SDK"] else {
            throw GeodePrepareError.geodeSDKMissing(
                "Download and install geode-sdk from `https://geode-sdk.org`")
        }
        let geodeSDKURL = URL(fileURLWithPath: geodeSDKPath)

        if !arguments.contains("--disable-sandbox") {
            throw GeodePrepareError.missingPermissions(
                "Command must be called as: `swift package geode-prepare --disable-sandbox` as"
                    + " GeodeSwift needs to call other build systems and modify this repository"
                    + " to get around Swift Package Managers limitations."
            )
        }

        print("Preparing Geode Swift directories")
        let buildURL = packageRootURL.appending(components: ".geode-swift")
        try fileManager.removeItem(at: buildURL)
        try fileManager.createDirectory(at: buildURL, withIntermediateDirectories: false)

        print("Building geode-sdk library for linking (this may take a while).")
        let geodeSDKArtifactsURL = buildURL.appending(components: "geode-sdk")
        try fileManager.createDirectory(
            at: geodeSDKArtifactsURL, withIntermediateDirectories: false)
        let dummyCMakeURL = pluginRootURL.appending(components: "assets/\(dummyCMakeName)")
        let copiedDummyCMakeURL = geodeSDKArtifactsURL.appending(component: dummyCMakeName)
        try fileManager.copyItem(at: dummyCMakeURL, to: copiedDummyCMakeURL)
        try run(
            executableURL: toolURLs["cmake"]!,
            arguments: [
                "-DDONT_INSTALL=YES",
                "-B", ".",
                "-G", "Ninja",
            ],
            executeInDirectory: geodeSDKArtifactsURL
        )
        try run(
            executableURL: toolURLs["cmake"]!,
            arguments: [
                "--build", geodeSDKArtifactsURL.path,
            ],
            executeInDirectory: geodeSDKArtifactsURL
        )
    }
}
