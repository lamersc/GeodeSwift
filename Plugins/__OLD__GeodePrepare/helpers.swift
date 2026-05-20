import Foundation

//{
//    "geode": "$GEODE_VERSION",
//    "gd": {
//        "win": "2.2081",
//        "android": "2.2081",
//        "mac": "2.2081",
//        "ios": "2.2081"
//    },
//    "id": "$MOD_ID",
//    "name": "$MOD_NAME",
//    "version": "$MOD_VERSION",
//    "developer": "$MOD_DEVELOPER",
//    "description": "$MOD_DESCRIPTION",
//    "dependencies": {
//        "geode.node-ids": ">=v1.23.3"
//    }
//}

struct GeodeConfig: Decodable, Encodable {
    var geode: String
    var gd: [String: String]
    var id: String
    var name: String
    var version: String
    var developer: String
    var description: String
    var dependencies: [String: String]

}

enum PluginError: Error {
    case processExitedWithError(executable: String, code: Int32)
}

public func run(executableURL: URL, arguments: [String], executeInDirectory: URL? = nil) throws
    -> String
{
    let process = Process()
    if let executeInDirectory {
        process.currentDirectoryURL = executeInDirectory
    }
    process.executableURL = executableURL
    process.arguments = arguments

    let stdoutPipe = Pipe()
    process.standardOutput = stdoutPipe

    try process.run()
    process.waitUntilExit()

    let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: stdoutData, encoding: .utf8) ?? ""

    guard process.terminationStatus == 0 else {
        throw PluginError.processExitedWithError(
            executable: executableURL.absoluteString,
            code: process.terminationStatus
        )
    }

    return output
}
