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
    var headerPathReplacements = {}

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

        let installedGeodeSDKURL = URL(
            fileURLWithPath: ProcessInfo.processInfo.environment["GEODE_SDK"]!)

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

        // cmake cache now contains cpm package paths for resolving where necessary headers are
        let cmakeCacheURL = geodeSDKArtifactsURL.appending(path: "CMakeCache.txt")
        let cmakeCacheContents = try String(contentsOf: cmakeCacheURL)
        let cmakeKeyValuePairs = try parseCMakeCache(contents: cmakeCacheContents)
        let CPM_PACKAGE_bindings_SOURCE_DIR = cmakeKeyValuePairs["CPM_PACKAGE_bindings_SOURCE_DIR"]!
        print("\(CPM_PACKAGE_bindings_SOURCE_DIR)")

        // now we can resolve all header paths
        let headerPathsListURL = pluginAssetsURL.appending(component: "headerPaths.txt")
        let headerPathsContents = try String(contentsOf: headerPathsListURL)

        let builtinResolvables = [
            "GEODE_SDK": installedGeodeSDKURL.path,
            "BUILD_DIR": geodeSDKArtifactsURL.path,
        ]
        let builtinReplacePattern = try Regex(#"@{(.+)}"#)
        let cmakeReplacePattern = try Regex(#"\${(.+)}"#)
        var resolvedHeaders: [String] = []
        headerPathsContents.enumerateLines(invoking: { line, stop in
            var cleanedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if let match = cleanedLine.firstMatch(of: builtinReplacePattern) {
                cleanedLine.replace(
                    builtinReplacePattern,
                    with: builtinResolvables[String(match[1].substring!)] ?? "")
            }
            if let match = cleanedLine.firstMatch(of: cmakeReplacePattern) {
                cleanedLine.replace(
                    cmakeReplacePattern, with: cmakeKeyValuePairs[match[1].substring!]!.value!)
            }
            resolvedHeaders.append(cleanedLine)
        })
        print("**headers**: \(resolvedHeaders)")

        return []

    }

    func errorMessage(_ msg: String) {
        Diagnostics.error(
            "\(msg)\n**Notice**: GeodeSwift is in early development. If this error wasn't expected, create an issue on Github."
        )
    }
}
