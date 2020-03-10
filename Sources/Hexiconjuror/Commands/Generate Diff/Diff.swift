import Foundation

struct FunctionInvocation: Hashable, LosslessStringConvertible {

    enum Arguments: Hashable, LosslessStringConvertible {

        private static let unlabeledRegex = try! RegularExpression(pattern: #"^\((\d+)\)$"#, options: [.anchorsMatchLines])
        private static let labeledFormatRegex = try! RegularExpression(pattern: #"^\((?:[a-z]{1}[a-z0-9]*:)+\)$"#, options: [.anchorsMatchLines])
        private static let labelExtractionRegex = try! RegularExpression(pattern: "([a-z]{1}[a-z0-9]*):", options: [.anchorsMatchLines])

        case empty
        case unlabeled(count: Int)
        case labeled([String])

        var description: String {
            switch self {
            case .empty: return "()"
            case .unlabeled(count: let count): return "(\(count))"
            case .labeled(let labels): return "(\(labels.map { $0 + ":" }.joined()))"
            }
        }

        init?(_ description: String) {
            if description == "()" {
                self = .empty
                return
            }
            if let count = Arguments.unlabeledRegex.firstMatch(in: description).flatMap(Int.init) {
                self = .unlabeled(count: count)
                return
            }
            guard Arguments.labeledFormatRegex.firstMatch(in: description) != nil else { return nil }
            let argumentLabels = Arguments.labelExtractionRegex.capturedGroups(in: description)
            guard argumentLabels.count == description.reduce(0, { $1 == ":" ? $0 + 1 : $0 }) else { return nil }
            self = .labeled(argumentLabels)
        }

    }

    var name: String
    var arguments: Arguments

    var description: String {
        "\(name)\(arguments)"
    }

    init(name: String = "", arguments: Arguments = .empty) {
        self.name = name
        self.arguments = arguments
    }

    init?(_ description: String) {
        guard let leftParen = description.firstIndex(of: "(") else { return nil }
        name = String(description[description.startIndex..<leftParen])
        guard let arguments = Arguments(String(description[leftParen..<description.endIndex])) else { return nil }
        self.arguments = arguments
    }

}

struct Diff: LosslessStringConvertible {

    private static let skippedSeparator = "\n== Skipped ==\n"
    private static let changesetSeparator = "\n====\n"

    var changes: [Changeset]
    var skipped = [String]()

    var description: String {
        let changesBody = changes.map(String.init(describing:)).joined(separator: type(of: self).changesetSeparator)
        guard skipped.count > 0 else { return changesBody }
        let skippedBody = skipped.map { "** \($0)" }.joined(separator: "\n")
        return changesBody + type(of: self).skippedSeparator + skippedBody
    }

    init(changes: [Changeset] = []) {
        self.changes = changes
    }

    init?(_ description: String) {
        // TODO
        let changesets = description
            .components(separatedBy: type(of: self).skippedSeparator)
            .prefix(1)
            .joined()
            .components(separatedBy: type(of: self).changesetSeparator)
            .map { Changeset.init($0) }
        if changesets.contains(where: { $0 == nil }) { return nil }
        changes = changesets.compactMap { $0 }
    }

}

struct Changeset: LosslessStringConvertible {

    enum Delimiter: String {
        case metadata = "@@"
        case addition = "++"
        case deletion = "--"

        func line<T: LosslessStringConvertible>(_ value: T) -> String {
            "\(self.rawValue) \(value)"
        }

        func parseValue<T: LosslessStringConvertible>(from line: String) -> T? {
            let lines = line.components(separatedBy: " ")
            guard lines.count == 2, lines.first == rawValue else { return nil }
            return T.init(lines[1])
        }
    }

    var file: URL
    var typeName: String
    var addedProperties = [String]()
    var addedFunctions = [FunctionInvocation]()
    var deletedProperties = [String]()
    var deletedFunctions = [FunctionInvocation]()

    var description: String {
        ([Delimiter.metadata.line(file), Delimiter.metadata.line(typeName)]
            + addedProperties.map(Delimiter.addition.line)
            + addedFunctions.map(Delimiter.addition.line)
            + deletedProperties.map(Delimiter.deletion.line)
            + deletedFunctions.map(Delimiter.deletion.line))
            .joined(separator: "\n")
    }

    var isEmpty: Bool {
        addedProperties.isEmpty && addedFunctions.isEmpty && deletedProperties.isEmpty && deletedFunctions.isEmpty
    }

    init(file: URL, typeName: String, addedProperties: [String] = [], addedFunctions: [FunctionInvocation] = [], deletedProperties: [String] = [], deletedFunctions: [FunctionInvocation] = []) {
        self.file = file
        self.typeName = typeName
        self.addedProperties = addedProperties.sorted()
        self.addedFunctions = addedFunctions.sorted { $0.name < $1.name }
        self.deletedProperties = deletedProperties.sorted()
        self.deletedFunctions = deletedFunctions.sorted { $0.name < $1.name }
    }

    init?(_ description: String) {
        let lines = description.components(separatedBy: "\n")
        guard lines.count > 2 else { return nil }
        guard let file: URL = Delimiter.metadata.parseValue(from: lines[0]) else { return nil }
        self.file = file
        guard let typeName: String = Delimiter.metadata.parseValue(from: lines[1]) else { return nil }
        self.typeName = typeName
        for line in lines.dropFirst(2) {
            if let addition: String = Delimiter.addition.parseValue(from: line) {
                FunctionInvocation(addition).map { addedFunctions.append($0) } ?? addedProperties.append(addition)
            } else if let deletion: String = Delimiter.deletion.parseValue(from: line) {
                FunctionInvocation(deletion).map { deletedFunctions.append($0) } ?? deletedProperties.append(deletion)
            } else {
                return nil
            }
        }
    }

}

extension URL: LosslessStringConvertible {
    public init?(_ description: String) {
        self.init(string: description)
    }
}


