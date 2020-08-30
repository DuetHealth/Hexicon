import Commandant
import Foundation
import Hexicon
import SwiftSyntax

final class GenerateDiff: ConjurorCommand {

    struct Options: OptionsProtocol {
        typealias ClientError = ConjurorError

        private static func create(_ definitionsPath: String) -> (String?) -> Options {
            { scanPath in Options(definitionsPath: definitionsPath, scanPath: scanPath) }
        }

        static func evaluate(_ m: CommandMode) -> Result<GenerateDiff.Options, CommandantError<ConjurorError>> {
            create
                <*> m <| Option(key: "def-path", defaultValue: "", usage: "Relative path to the files which contain the string definition namespaces.")
                <*> m <| Option(key: "scan-path", defaultValue: nil, usage: "Relative path to the files which should be scanned for string usages.")
        }

        let definitionsPath: String
        let scanPath: String?

    }

    let verb = "diff"
    let function = "Generates a diff between the currently-defined string symbols and all used string symbols."

    func run(_ options: GenerateDiff.Options) -> Result<Diff, ConjurorError> {
        let projectPath = environment.projectPath
        do {
            let definitionsPath = projectPath.appendingPathComponent(options.definitionsPath)
            let definitionFiles = Array(FileManager.default.enumerator(at: definitionsPath, includingPropertiesForKeys: nil)!.lazy
                .compactMap { $0 as? URL })
                .filter { $0.pathExtension == "swift" }
            let existingDefinitions = ExistingStringDefinitions(files: definitionFiles)
            try existingDefinitions.walkFiles()
            let scanPath = options.scanPath.map(projectPath.appendingPathComponent) ?? projectPath
            let scannedFiles = Array(FileManager.default.enumerator(at: scanPath, includingPropertiesForKeys: nil)!.lazy
                .compactMap { $0 as? URL })
                .filter { $0.pathExtension == "swift" }
            let references = AllStringReferences(files: scannedFiles, namespaces: existingDefinitions.allNamespaces)
            try references.walkFiles()
#if DEBUG
            let diff = existingDefinitions.generateDiff(between: references)
            print(diff)
            return .success(diff)
#else
            return .success(existingDefinitions.generateDiff(between: references))
#endif
        } catch { fatalError("Encountered an uncaught error: \(error). Please add instructions on how to fix this error!") }
    }

}

fileprivate extension GenerateDiff {

    class ExistingStringDefinitions: SyntaxVisitor {

        private struct Namespace: Hashable {
            var originFile: URL?
            var fullTypeName = ""
            var properties = Set<String>()
            var functions = Set<FunctionInvocation>()
        }

        private let files: [URL]

        // TODO: Allow adding definitions to the root namespace.
        // private lazy var rootNamespace = Namespace(fullTypeName: Constants.rootNamespace)
        private var customNamespaces = Set<Namespace>()
        private var currentFile: URL?
        private var inProgressNamespace: Namespace?
        private var potentialProperty: String?
        private var inProgressFunction: FunctionInvocation?

        var allNamespaces: [String] {
            [Constants.rootNamespace] + customNamespaces.map { $0.fullTypeName }
        }

        init(files: [URL]) {
            self.files = files
        }

        func walkFiles() throws {
            try files.forEach {
                currentFile = $0
                walk(try SyntaxParser.parse($0))
            }
        }

        override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
            return String(describing: node.extendedType.withoutTrivia()) == Constants.rootNamespace ? .visitChildren : .skipChildren
        }

        override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
            guard node.inheritanceClause?.inherits(LocalizationNamespace.self) ?? false, inProgressNamespace == nil else { return .skipChildren }
            inProgressNamespace = Namespace(originFile: currentFile, fullTypeName: "\(Constants.rootNamespace).\(node.identifier.text)")
            return .visitChildren
        }

        override func visitPost(_ node: ClassDeclSyntax) {
            guard let namespace = inProgressNamespace else { return }
            customNamespaces.insert(namespace)
            inProgressNamespace = nil
        }

        override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
            return node.modifiers?.isStatic ?? false ? .visitChildren : .skipChildren
        }


        override func visit(_ node: IdentifierPatternSyntax) -> SyntaxVisitorContinueKind {
            potentialProperty = node.identifier.text.replacingOccurrences(of: "`", with: "")
            return .visitChildren
        }

        override func visit(_ node: SimpleTypeIdentifierSyntax) -> SyntaxVisitorContinueKind {
            if potentialProperty != nil && node.name.text != String(describing: String.self) {
                potentialProperty = nil
            }
            return .visitChildren
        }


        override func visitPost(_ node: VariableDeclSyntax) {
            guard let property = potentialProperty else { return }
            inProgressNamespace?.properties.insert(property)
            potentialProperty = nil
        }

        override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
            guard inProgressNamespace != nil, node.modifiers?.isStatic ?? false else { return .skipChildren }
            inProgressFunction = FunctionInvocation(name: node.identifier.withoutTrivia().text)
            return .visitChildren
        }

        override func visit(_ node: ParameterClauseSyntax) -> SyntaxVisitorContinueKind {
            guard inProgressFunction != nil else { return .skipChildren }
            guard let isUnlabeled = node.parameterList.first?.isWildcard else { return .visitChildren }
            guard node.parameterList.allSatisfy({ isUnlabeled == $0.isWildcard }) else { return .skipChildren }
            if isUnlabeled {
                inProgressFunction?.arguments = .unlabeled(count: node.parameterList.count)
            } else {
                inProgressFunction?.arguments = .labeled(node.parameterList.map { String(describing: $0.firstName!) })
            }
            return .visitChildren
        }

        override func visit(_ node: ReturnClauseSyntax) -> SyntaxVisitorContinueKind {
            if String(describing: node.returnType.withoutTrivia()) != String(describing: String.self) {
                inProgressFunction = nil
            }
            return .skipChildren
        }

        override func visitPost(_ node: FunctionDeclSyntax) {
            guard let function = inProgressFunction else { return }
            inProgressNamespace?.functions.insert(function)
            inProgressFunction = nil
        }

        func generateDiff(between allReferences: AllStringReferences) -> Diff {
            var diff = Diff()
            diff.skipped = allReferences.skippedReferences
            allReferences.candidates.forEach { candidate in
                guard let namespace = customNamespaces.first(where: { $0.fullTypeName == candidate.namespace }) else { return }
                let addedProperties = Array(candidate.properties.subtracting(namespace.properties))
                let addedFunctions = Array(candidate.functions.subtracting(namespace.functions))
                let deletedProperties = Array(namespace.properties.subtracting(candidate.properties))
                let deletedFunctions = Array(namespace.functions.subtracting(candidate.functions))
                let changeset = Changeset(file: namespace.originFile!, typeName: candidate.namespace, addedProperties: addedProperties, addedFunctions: addedFunctions, deletedProperties: deletedProperties, deletedFunctions: deletedFunctions)
                if changeset.isEmpty { return }
                diff.changes.append(changeset)
            }
            return diff
        }

    }

}

fileprivate extension GenerateDiff {

    class AllStringReferences: SyntaxVisitor {

        struct NamespaceCandidates: Hashable {
            var namespace: String
            var properties = Set<String>()
            var functions = Set<FunctionInvocation>()
        }

        private let files: [URL]
        private var candidatesDictionary: [String: NamespaceCandidates]
        private(set) var skippedReferences = [String]()

        var candidates: [NamespaceCandidates] {
            Array(candidatesDictionary.values)
        }

        init(files: [URL], namespaces: [String]) {
            self.files = files
            self.candidatesDictionary = Dictionary(uniqueKeysWithValues: namespaces.map { ($0, NamespaceCandidates(namespace: $0)) })
        }

        func walkFiles() throws {
            try files.forEach { walk(try SyntaxParser.parse($0)) }
        }

        override func visitPost(_ node: MemberAccessExprSyntax) {
            let fullName = String(describing: node.withoutTrivia())
            guard fullName.hasPrefix(Constants.rootNamespace) else { return }
            let nameComponents = fullName.components(separatedBy: ".")
            if let lastComponent = nameComponents.last, lastComponent == lastComponent.capitalized { return }
            let parent = nameComponents.dropLast().joined(separator: ".")
            guard var candidate = candidatesDictionary[parent] else {
                skippedReferences.append(fullName)
                return
            }
            candidate.properties.insert(node.name.text)
            candidatesDictionary[parent] = candidate
        }

        override func visitPost(_ node: FunctionCallExprSyntax) {
            let fullDefinition = String(describing: node.withoutTrivia())
            guard fullDefinition.hasPrefix(Constants.rootNamespace) else { return }
            guard let fullName = fullDefinition.components(separatedBy: "(").first else { return }
            let nameComponents = fullName.components(separatedBy: ".")
            guard let functionName = nameComponents.last, functionName != functionName.capitalized else { return }
            let namespace = nameComponents.dropLast().joined(separator: ".")
            guard var candidate = candidatesDictionary[namespace] else {
                skippedReferences.append(fullName)
                return
            }
            // Functions will be initially processed as properties, so we should remove them.
            candidate.properties.remove(functionName)
            guard node.argumentList.count > 0 else {
                candidate.functions.insert(FunctionInvocation(name: functionName, arguments: .empty))
                return
            }
            let labeled = node.argumentList.first?.label != nil
            guard node.argumentList.allSatisfy({ labeled == ($0.label != nil) }) else { return }
            if labeled {
                candidate.functions.insert(FunctionInvocation(name: functionName, arguments: .labeled(node.argumentList.map { String(describing: $0.label!) })))
            } else {
                candidate.functions.insert(FunctionInvocation(name: functionName, arguments: .unlabeled(count: node.argumentList.count)))
            }
            candidatesDictionary[namespace] = candidate
        }

    }

}
