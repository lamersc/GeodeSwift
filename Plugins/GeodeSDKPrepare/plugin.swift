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
        let packageRootURL = context.package.directoryURL

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

        // prepare geode swift directories
        let buildURL = packageRootURL.appending(components: ".geode-swift")
        try fileManager.removeItem(at: buildURL)
        try fileManager.createDirectory(at: buildURL, withIntermediateDirectories: false)
        //Diagnostics.error("\(ProcessInfo.processInfo.environment)")
        //ProcessInfo.processInfo.environment
        // let toolURLs = [
        //     "git": try context.tool(named: "git").url,
        //     "cmake": try context.tool(named: "cmake").url,
        //     "geode": try context.tool(named: "geode").url,
        // ]

        // fileManager.createFile(atPath: dummyCMakeURL.path, contents: nil)
        // print("Root: \(packageRootURL)")
        return []

    }

    func errorMessage(_ msg: String) {
        Diagnostics.error(
            "\(msg)\n**Notice**: GeodeSwift is in early development. If this error wasn't expected, create an issue on Github."
        )
    }
}
