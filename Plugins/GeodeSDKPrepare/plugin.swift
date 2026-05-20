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

        let packageRootURL = context.package.directoryURL
        let number = Int.random(in: 0..<100000)
        let dummyCMakeURL = packageRootURL.appending(components: "Package.swift")
        fileManager.removeItem(at: dummyCMakeURL)
        // fileManager.createFile(atPath: dummyCMakeURL.path, contents: nil)
        // print("Root: \(packageRootURL)")
        return []

    }
}
