import Commandant
import Foundation
import SwiftSyntax

enum ConjurorError: String, Error {
    case invalidArguments
    case invalidDiff = "The supplied diff is not valid"
}

extension CommandRegistry {

    func main(errorHandler: @escaping (ClientError) -> ()) -> Never {
        let help = HelpCommand(registry: self)
        register(help)
        return main(defaultVerb: help.verb, errorHandler: errorHandler)
    }

}

extension CommandRegistry {

    struct Registration<E: EnvironmentObject> {

        private let call: (CommandRegistry, E) -> ()

        init(_ call: @escaping (CommandRegistry, E) -> ()) {
            self.call = call
        }

        func callAsFunction(registry: CommandRegistry, environment: E) {
            call(registry, environment)
        }

    }

    @_functionBuilder struct CommandBuilder {

        static func buildBlock<C1: ConjurorCommand, C2: ConjurorCommand>(_ c1: C1, _ c2: C2) -> [Registration<C1.Environment>] where C1.ClientError == ClientError, C2.ClientError == ClientError, C1.Environment == C2.Environment {
            return [
                Registration<C1.Environment> { (r: CommandRegistry<C1.ClientError>, env: C1.Environment) in r.register(c1.with(env)) },
                Registration<C2.Environment> { (r: CommandRegistry<C2.ClientError>, env: C2.Environment) in r.register(c2.with(env)) },
            ]
        }

        static func buildBlock<C1: ConjurorCommand, C2: ConjurorCommand, C3: ConjurorCommand>(_ c1: C1, _ c2: C2, _ c3: C3) -> [Registration<C1.Environment>] where C1.ClientError == ClientError, C2.ClientError == ClientError, C3.ClientError == ClientError, C1.Environment == C2.Environment, C1.Environment == C3.Environment {
            return [
                Registration<C1.Environment> { (r: CommandRegistry<C1.ClientError>, env: C1.Environment) in r.register(c1.with(env)) },
                Registration<C2.Environment> { (r: CommandRegistry<C2.ClientError>, env: C2.Environment) in r.register(c2.with(env)) },
                Registration<C3.Environment> { (r: CommandRegistry<C3.ClientError>, env: C3.Environment) in r.register(c3.with(env)) },
            ]
        }

        static func buildBlock<C1: ConjurorCommand, C2: ConjurorCommand, C3: ConjurorCommand, C4: ConjurorCommand>(_ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4) -> [Registration<C1.Environment>] where C1.ClientError == ClientError, C2.ClientError == ClientError, C3.ClientError == ClientError, C4.ClientError == ClientError, C1.Environment == C2.Environment, C1.Environment == C3.Environment, C1.Environment == C4.Environment {
            return [
                Registration<C1.Environment> { (r: CommandRegistry<C1.ClientError>, env: C1.Environment) in r.register(c1.with(env)) },
                Registration<C2.Environment> { (r: CommandRegistry<C2.ClientError>, env: C2.Environment) in r.register(c2.with(env)) },
                Registration<C3.Environment> { (r: CommandRegistry<C3.ClientError>, env: C3.Environment) in r.register(c3.with(env)) },
                Registration<C4.Environment> { (r: CommandRegistry<C4.ClientError>, env: C4.Environment) in r.register(c4.with(env)) },
            ]
        }

    }

    func register<E: EnvironmentObject>(with environment: E, @CommandBuilder _ builder: () -> [Registration<E>]) -> CommandRegistry {
        builder().forEach { $0(registry: self, environment: environment) }
        register(HelpCommand(registry: self))
        return self
    }

}

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
        RunGeneration()
    }
    .main(defaultVerb: "run") { _ in }
