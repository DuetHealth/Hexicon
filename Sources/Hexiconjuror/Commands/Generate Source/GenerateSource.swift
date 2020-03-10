import Commandant
import Foundation
import SwiftSyntax

final class GenerateSource: ConjurorCommand {
    typealias ClientError = ConjurorError

    struct Options: OptionsProtocol {

        static func evaluate(_ m: CommandMode) -> Result<GenerateSource.Options, CommandantError<ConjurorError>> {
            { diff in Options(diff: diff) }
                <*> m <| Option(key: "diff", defaultValue: "", usage: "The diff to apply. Required.")
        }
        
        typealias ClientError = ConjurorError

        let diff: String

        func with(diff: Diff) -> Options {
            Options(diff: diff.description)
        }

    }

    let verb = "generate-source"
    let function = "Generates the source code containing string definitions based on a particular diff."

    func run(_ options: GenerateSource.Options) -> Result<(), ConjurorError> {
        let modifier = SourceModifier()
        guard let diff = Diff(options.diff) else { return .success(()) }
        try! diff.changes.forEach { try modifier.applyChanges(in: $0) }
        return .success(())
    }

}

fileprivate extension GenerateSource {

    class SourceModifier: SyntaxRewriter {

        private var currentChangeset: Changeset!
        private var isWithinNamespaceScope = false

        func applyChanges(in changeset: Changeset) throws {
            currentChangeset = changeset
            let updatedSyntax = visit(try SyntaxParser.parse(changeset.file))
#if DEBUG
            print(changeset.file)
            print(updatedSyntax)
#endif
            var stream = try FileOutputStream(url: changeset.file)
            updatedSyntax.write(to: &stream)
        }

        override func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
            guard currentChangeset.typeName.hasPrefix(String(describing: node.extendedType.withoutTrivia())) else { return DeclSyntax(node) }
            return DeclSyntax(node.withMembers(MemberDeclBlockSyntax(visit(node.members))))
        }

        override func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
            guard currentChangeset.typeName.hasSuffix(String(describing: node.identifier.withoutTrivia())) else { return DeclSyntax(node) }
            isWithinNamespaceScope = true
            let newSyntax = DeclSyntax(node.withMembers(MemberDeclBlockSyntax(visit(node.members))))
            isWithinNamespaceScope = false
            return newSyntax
        }

        override func visit(_ node: MemberDeclListSyntax) -> Syntax {
            guard isWithinNamespaceScope else { return super.visit(node) }
            var node = node
            // The default value is inferred from the structure of a default namespace file.
            let leadingTrivia = node.children.first?.leadingTrivia ?? (node.parent?.leadingTrivia ?? []) + [.newlines(2), .spaces(8)]
            let children = Array(node.children)
                .compactMap { $0.as(MemberDeclListItemSyntax.self) }
            let existingProperties = children.compactMap { $0.children.first?.as(VariableDeclSyntax.self) }
                .filter { !currentChangeset.deletedProperties.contains($0.variableName) }
            let newProperties = currentChangeset.addedProperties.map { propertyName in
                VariableDeclSyntax(newProperty(named: propertyName).resolve(leadingTrivia: leadingTrivia))!
            }
            let existingFunctions = children.compactMap { $0.children.first?.as(FunctionDeclSyntax.self) }
                .filter { function in
                    !currentChangeset.deletedFunctions.contains {
                        $0.name == function.functionName && $0.arguments == function.argumentLabels
                    }
                }
            let newFunctions = currentChangeset.addedFunctions.map { invocation in
                FunctionDeclSyntax(newFunction(from: invocation).resolve(leadingTrivia: leadingTrivia))!
            }
            (0..<node.children.count).forEach { _ in node.remove(childAt: 0) }
            (existingProperties + newProperties)
                .sorted { $0.variableName < $1.variableName }
                .forEach { node.append(MemberDeclListItemSyntax($0)) }
            (existingFunctions + newFunctions)
                .sorted { $0.functionName < $1.functionName }
                .forEach { node.append(MemberDeclListItemSyntax($0)) }
            return Syntax(node)
        }

        private func newProperty(named propertyName: String) -> VariableDecl {
            VariableDecl {
                Static()
                    .trivia(trailing: .space)
                Var()
                    .trivia(trailing: .space)
                Pattern {
                    Identifier(propertyName)
                    TypeAnnotation(String.self)
                        .trivia(trailing: .space)
                    FunctionBody {
                        Unknown(#"NSLocalizedString("\#(propertyName)", bundle: bundle, comment: "")"#)
                    }
                }
            }
        }

        private func newFunction(from invocation: FunctionInvocation) -> FunctionDecl {
            FunctionDecl {
                Static()
                    .trivia(trailing: .space)
                Identifier(invocation.name)
                Signature {
                    ParameterList {
                        switch invocation.arguments {
                        case .empty:
                            return []
                        case .unlabeled(let count):
                            return (1...count).map { Parameter(name: "value\($0)", type: Any.self) }
                        case .labeled(let labels):
                            return labels.map { Parameter(label: $0, type: Any.self) }
                        }
                    }
                    Return(String.self)
                }
                FunctionBody {
                    Unknown(#"String(format: NSLocalizedString("\#(invocation.name)", bundle: bundle, comment: ""))"#)
                }
            }
        }

    }

}
