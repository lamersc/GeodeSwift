import Foundation
import PackagePlugin

enum GeodeSDKPrepareError: Error {
    case geodeSDKMissing(_ msg: String)
    case missingPermissions(_ msg: String)
}

@main
struct GeodeSDKPrepare: BuildToolPlugin {
    let fileManager = FileManager.default
    let dummyCMakeName = "CMakeLists.txt"

    func createBuildCommands(
        context: PluginContext,
        target: Target
    ) throws -> [Command] {
        let pluginRootURL = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        let pluginAssetsURL = pluginRootURL.appending(component: "assets")
        let packageRootURL = context.package.directoryURL
        let buildURL = packageRootURL.appending(component: ".geode-swift")

        let geodeAlreadyConfigured = fileManager.fileExists(atPath: buildURL.path)
        if geodeAlreadyConfigured {
            return []
        }

        guard let gitURL = try findTool(named: "git") else {
            errorMessage("Could not locate `git` command on your system.")
            return []
        }
        guard let cmakeURL = try findTool(named: "cmake") else {
            errorMessage("Could not locate `cmake` command on your system.")
            return []
        }
        guard let geodeURL = try findTool(named: "geode") else {
            errorMessage("Could not locate `geode` command on your system.")
            return []
        }

        // prepare geode swift build directory and relevant paths
        let geodeSDKArtifactsURL = buildURL.appending(component: "geode-sdk")
        try fileManager.createDirectory(at: geodeSDKArtifactsURL, withIntermediateDirectories: true)

        // build geode-sdk using template to get static lib
        let templateCMakeURL = pluginAssetsURL.appending(components: "CMakeLists.txt")
        let targetCMakeURL = geodeSDKArtifactsURL.appending(component: "CMakeLists.txt")
        try fileManager.copyItem(at: templateCMakeURL, to: targetCMakeURL)

        let templateModJsonURL = pluginAssetsURL.appending(components: "mod.json")
        let targetModJsonURL = geodeSDKArtifactsURL.appending(component: "mod.json")
        try fileManager.copyItem(at: templateModJsonURL, to: targetModJsonURL)

        try run(
            executableURL: cmakeURL,
            arguments: [
                "-B", ".",
                "-G", "Ninja",
            ],
            executeInDirectory: geodeSDKArtifactsURL
        )

        try run(
            executableURL: cmakeURL,
            arguments: [
                "--build", geodeSDKArtifactsURL.path,
            ],
            executeInDirectory: geodeSDKArtifactsURL
        )

        return []

    }

    func errorMessage(_ msg: String) {
        Diagnostics.error(
            "\(msg)\n**Notice**: GeodeSwift is in early development. If this error wasn't expected, create an issue on Github."
        )
    }
}
