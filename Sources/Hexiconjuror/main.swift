import Commandant
import Foundation
import SwiftSyntax

#if DEBUG
print(FileManager.default.currentDirectoryPath)
let environment = DebugVariables([
    "PROJECT_DIR": (#file.components(separatedBy: "Sources").first! as NSString).appendingPathComponent("Sample")
])
#else
let environment = EnvironmentVariables()
#endif

CommandRegistry<ConjurorError>()
    .register(with: environment) {
        GenerateDiff().toStandardOutput()
        GenerateNamespace()
        GenerateSource()
        OutputStrings()
        RunGeneration()
    }
    .main(defaultVerb: "run") { _ in }
