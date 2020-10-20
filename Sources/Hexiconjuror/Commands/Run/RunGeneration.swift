import Commandant
import Foundation

// TODO: it would be better to define a protocol for a type of command which is composed of other commands.
// Those those commands would need to be related to each other by the result type of the command before it.
final class RunGeneration: ConjurorCommand {

    let verb = "run"
    let function = "Generates a diff between the currently-defined string symbols and all used string symbols, generates the source code containing string definitions based on a particular diff, and emits the generated source into the destination file."

    func run(_ options: UnionOptions<GenerateDiff.Options, GenerateSource.Options>) -> Result<(), ConjurorError> {
        let generateDiff = GenerateDiff().with(environment)
        let generateSource = GenerateSource().with(environment)
        return generateDiff.run(options.options1)
            .flatMap { generateSource.run(options.options2.with(diff: $0)) }
    }

}

struct UnionOptions<O1: OptionsProtocol, O2: OptionsProtocol>: OptionsProtocol where O1.ClientError == ConjurorError, O2.ClientError == ConjurorError {

    static func evaluate(_ m: CommandMode) -> Result<UnionOptions<O1, O2>, CommandantError<ConjurorError>> {
        Result { try UnionOptions<O1, O2>(options1: O1.evaluate(m).get(), options2: O2.evaluate(m).get()) }
            .mapError { $0 as! CommandantError<ConjurorError> }
    }

    let options1: O1
    let options2: O2

}
