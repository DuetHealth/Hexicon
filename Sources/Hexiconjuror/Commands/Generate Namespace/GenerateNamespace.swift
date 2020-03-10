import Commandant
import Foundation
import Hexicon
import SwiftSyntax

final class GenerateNamespace: ConjurorCommand {

    struct Options: OptionsProtocol {

        let namespaceName: String
        let outputPath: String?

        private static func create(_ name: String) -> (String?) -> Options {
            { path in Options(namespaceName: name, outputPath: path) }
        }

        static func evaluate(_ m: CommandMode) -> Result<GenerateNamespace.Options, CommandantError<ConjurorError>> {
            create
                <*> m <| Option(key: "name", defaultValue: "", usage: "The name of the new namespace. Required.")
                <*> m <| Option(key: "outputPath", defaultValue: nil, usage: "The path to the new file. If the path does not end in a file name, the file name 'Strings.swift' is used.")
        }

    }

    let verb = "generate-namespace"
    let function = "Creates a new source file containing an empty localization namespace."

    func run(_ options: Options) -> Result<(), ConjurorError> {
        guard !options.namespaceName.isEmpty else { return .failure(ConjurorError.invalidArguments) }
        var outputStream: FileOutputStream
        do {
            let pwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            let baseURL: URL
            if let outputPath = options.outputPath {
                baseURL = outputPath.starts(with: "/") ? URL(fileURLWithPath: outputPath) : URL(fileURLWithPath: outputPath, relativeTo: pwd)
            } else {
                baseURL = pwd
            }
            let sourceFileURL = baseURL.pathExtension != "swift" ? baseURL.appendingPathComponent("Strings.swift") : baseURL
            FileManager.default.createFile(atPath: sourceFileURL.path, contents: nil, attributes: nil)
            outputStream = try FileOutputStream(url: sourceFileURL)
        } catch {
            fatalError()
        }
        // TODO: Convert to DSL
        CodeBlockSyntax { builder in
            builder.addStatement(CodeBlockItemSyntax { builder in
                builder.useItem(Syntax(ImportDeclSyntax { builder in
                    builder.useImportTok(SyntaxFactory.makeImportKeyword(trailingTrivia: .spaces(1)))
                    builder.addPathComponent(AccessPathComponentSyntax { builder in
                        builder.useName(SyntaxFactory.makeIdentifier("Hexicon", trailingTrivia: .newlines(2)))
                    })
                }))
            })
            builder.addStatement(CodeBlockItemSyntax { builder in
                builder.useItem(Syntax(ExtensionDeclSyntax { builder in
                    builder.useExtensionKeyword(SyntaxFactory.makeExtensionKeyword(trailingTrivia: .spaces(1)))
                    builder.useExtendedType(SyntaxFactory.makeTypeIdentifier(Constants.rootNamespace, trailingTrivia: .spaces(1)))
                    builder.useMembers(MemberDeclBlockSyntax { builder in
                        builder.useLeftBrace(SyntaxFactory.makeLeftBraceToken(trailingTrivia: [.newlines(2), .spaces(4)]))
                        builder.addMember(MemberDeclListItemSyntax { builder in
                            builder.useDecl(DeclSyntax(ClassDeclSyntax { builder in
                                builder.useClassKeyword(SyntaxFactory.makeClassKeyword(trailingTrivia: .spaces(1)))
                                builder.useIdentifier(SyntaxFactory.makeIdentifier(options.namespaceName))
                                builder.useInheritanceClause(TypeInheritanceClauseSyntax { builder in
                                    builder.useColon(SyntaxFactory.makeColonToken(trailingTrivia: .spaces(1)))
                                    builder.addInheritedType(InheritedTypeSyntax { builder in
                                        builder.useTypeName(SyntaxFactory.makeTypeIdentifier(String(describing: LocalizationNamespace.self), trailingTrivia: .spaces(1)))
                                    })
                                })
                                builder.useMembers(MemberDeclBlockSyntax { builder in
                                    builder.useLeftBrace(SyntaxFactory.makeLeftBraceToken(trailingTrivia: [.newlines(2), .spaces(4)]))
                                    builder.useRightBrace(SyntaxFactory.makeRightBraceToken(trailingTrivia: .newlines(2)))
                                })
                            }))
                        })
                        builder.useRightBrace(SyntaxFactory.makeRightBraceToken(trailingTrivia: .newlines(1)))
                    })
                }))
            })
        }
            .write(to: &outputStream)
        return .success(())
    }

}
//
//struct TestOptions: OptionsProtocol, ReflexiveOptions {
//    typealias ClientError = ConjurorError
//
//    @FromOption("name", usage: "", default: "") var test
//
//}
//
//// TODO
//protocol ReflexiveOptions {
//    init()
//}
//
//extension OptionsProtocol where Self: ReflexiveOptions {
//
//
//
//    static func evaluate(_ m: CommandMode) -> Result<Self, CommandantError<ClientError>> {
//        let value = self.init()
//        Mirror(reflecting: value).children.compactMap { child in
//            guard let option =
//        }
//    }
//
//}
//
//
//fileprivate protocol OptionProtocol {
//    var key: String { get }
//    var usage: String { get }
//    mutating func parseValue(from string: String)
//}
//
//@propertyWrapper struct FromOption<Value: LosslessStringConvertible>: OptionProtocol {
//
//    var key: String
//    var usage: String
//    var wrappedValue: Value
//
//    init(_ key: String, usage: String, default defaultValue: Value) {
//        self.key = key
//        self.usage = usage
//        self.wrappedValue = defaultValue
//    }
//
//    mutating func parseValue(from string: String) {
//        if let value = Value.init(string) {
//            wrappedValue = value
//        }
//    }
//
//}
