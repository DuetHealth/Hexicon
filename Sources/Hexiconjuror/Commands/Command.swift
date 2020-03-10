import Commandant
import Foundation

fileprivate var environmentKey = UInt8.zero

protocol Command: AnyObject, CommandProtocol {
    associatedtype Environment: EnvironmentObject
    var environment: Environment { get }
    func with(_ environment: Environment) -> Self
}

extension Command where Environment == EnvironmentVariables {

    var environment: EnvironmentVariables {
        guard let environment = objc_getAssociatedObject(self, &environmentKey) as? EnvironmentVariables else {
            fatalError("The command was not supplied with an Environment.")
        }
        return environment
    }

    func with(_ environment: EnvironmentVariables) -> Self {
        objc_setAssociatedObject(self, &environmentKey, environment, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return self
    }

}

protocol ConjurorCommand: Command where ClientError == ConjurorError, Environment == EnvironmentVariables {
    associatedtype CommandOutput

    func run(_ options: Options) -> Result<CommandOutput, ClientError>

}

extension ConjurorCommand {

    func run(_ options: Options) -> Result<(), ClientError> {
        run(options).map { _ in () }
    }

}

fileprivate final class StandardOutputProxy<C: ConjurorCommand>: ConjurorCommand where C.CommandOutput: CustomStringConvertible {
    typealias Options = C.Options
    typealias ClientError = C.ClientError

    private let command: C

    var verb: String { command.verb }
    var function: String { command.function }

    init(_ command: C) {
        self.command = command
    }

    func run(_ options: C.Options) -> Result<(), ConjurorError> {
        let result = command.run(options)
        if case .success(let output) = result { print(output) }
        return result.map { _ in () }
    }

    func with(_ environment: EnvironmentVariables) -> StandardOutputProxy<C> {
        _ = command.with(environment)
        return self
    }

}

extension ConjurorCommand where CommandOutput: CustomStringConvertible {

    func toStandardOutput() -> some ConjurorCommand {
        StandardOutputProxy(self)
    }

}
