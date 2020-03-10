import Foundation

class EnvironmentVariables: EnvironmentObject {

    @EnvironmentVariable("PROJECT_DIR", via: URL.init(fileURLWithPath:)) var projectPath

    override subscript(key: String) -> String? {
        ProcessInfo.processInfo.environment[key]
    }

}

#if DEBUG

class DebugVariables: EnvironmentVariables {

    private let customValues: [String: String]

    init(_ customValues: [String: String]) {
        self.customValues = customValues
    }

    override subscript(key: String) -> String? {
        customValues[key] ?? super[key]
    }

}

#endif
