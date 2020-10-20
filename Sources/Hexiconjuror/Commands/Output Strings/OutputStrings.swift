import Commandant
import Foundation

final class OutputStrings: ConjurorCommand {
    typealias ClientError = ConjurorError

    struct Options: OptionsProtocol {
        typealias ClientError = ConjurorError

        static func create(_ definitionsPath: String) -> (String) -> (Bool) -> Options {
            { resourcesPath in { Options(definitionsPath: definitionsPath, resourcesPath: resourcesPath, stripEmptyComments: $0) } }
        }

        static func evaluate(_ m: CommandMode) -> Result<OutputStrings.Options, CommandantError<ConjurorError>> {
            create
                <*> m <| Option(key: "def-path", defaultValue: "", usage: "Relative path to the files which contain the string definition namespaces.")
                <*> m <| Option(key: "res-path", defaultValue: "", usage: "Relative path to the strings files.")
                <*> m <| Switch(key: "strip-comments", usage: "Whether to remove from the output file which have no engineer-provided comment.")
        }

        let definitionsPath: String
        let resourcesPath: String
        let stripEmptyComments: Bool

    }

    let verb = "output-strings"
    let function = "Outputs and sorts all localized strings into their respective tables, preserving existing and deleting unused translations."
    private let parser = StringsParser()

    func run(_ options: OutputStrings.Options) -> Result<(), ConjurorError> {
        let sourcePath = options.definitionsPath.isEmpty ? environment.projectPath : environment.projectPath.appendingPathComponent(options.definitionsPath)
        let sourceFiles = FileManager.default.enumerator(at: sourcePath, includingPropertiesForKeys: [.isRegularFileKey])?
            .compactMap { $0 as? URL }
            .filter { $0.pathExtension == "swift" } ?? []
        let resourcesPath = options.resourcesPath.isEmpty ? environment.projectPath : environment.projectPath.appendingPathComponent(options.resourcesPath)
        let stringsFiles = FileManager.default.enumerator(at: resourcesPath, includingPropertiesForKeys: [.isRegularFileKey])?
            .compactMap { $0 as? URL }
            .filter { $0.pathExtension == "strings" } ?? []
        let temporaryDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        return Result {
            try FileManager.default.createDirectory(atPath: temporaryDirectory.path, withIntermediateDirectories: false, attributes: nil)
        }
            .flatMapCatching { files in
                let localize = Process()
                let arguments = "/usr/bin/xcrun extractLocStrings -o \(temporaryDirectory.path)"
                    .split(separator: " ").map(String.init)
                    + sourceFiles.map { $0.path }
                localize.executableURL = URL(fileURLWithPath: arguments[0])
                localize.arguments = Array(arguments.dropFirst())
                try localize.run()
                localize.waitUntilExit()
            }
            .flatMapCatching {
                let existingTables = try stringsFiles.map {
                    try Table(url: $0, strings: parser.parse(file: $0))
                }
                let newTables = try FileManager.default.contentsOfDirectory(at: temporaryDirectory, includingPropertiesForKeys: [.isRegularFileKey], options: [])
                    .filter { $0.pathExtension == "strings" }
                    .map { return try Table(url: $0, strings: parser.parse(file: $0)) }
                return Array(newTables.map { newTable -> [Table] in
                    let matches = existingTables.filter { $0.name == newTable.name }
                    guard !matches.isEmpty else {
                        return [mutate(newTable) { $0.url = resourcesPath.appendingPathComponent("\($0.name).strings") }]
                    }
                    return matches.map {
                        var matchingTable = $0
                        newTable.strings.forEach { newString in
                            guard var string = matchingTable.strings[newString.key] else {
                                matchingTable.strings[newString.key] = newString.value
                                return
                            }
                            if string.hasEmptyComment {
                                string.comment = newString.value.comment
                            }
                            matchingTable.strings[newString.key] = string
                        }
                        matchingTable.strings = matchingTable.strings.filter {
                            newTable.strings[$0.key] != nil
                        }
                        return matchingTable
                    }
                }
                    .joined())
            }
            .flatMapCatching { (tables: [Table]) in
                try tables.forEach { table in
                    let oldFile = temporaryDirectory.appendingPathComponent(UUID().uuidString)
                    let tempFile = temporaryDirectory.appendingPathComponent(UUID().uuidString)
                    FileManager.default.createFile(atPath: tempFile.path, contents: nil, attributes: nil)
                    try table.write(to: tempFile, stripEmptyComments: options.stripEmptyComments)
                    if FileManager.default.fileExists(atPath: table.url.path) {
                        try FileManager.default.moveItem(at: table.url, to: oldFile)
                    }
                    do {
                        try FileManager.default.moveItem(at: tempFile, to: table.url)
                    } catch {
                        try FileManager.default.moveItem(at: oldFile, to: table.url)
                    }
                }
            }
            .mapError { _ in ConjurorError.invalidArguments }
    }


}

extension OutputStrings {

    private struct Table {

        var url: URL
        var strings: [String: LocalizedString]

        var name: String { url.resourceName }

        func write(to url: URL, stripEmptyComments: Bool) throws {
            var stream = try FileOutputStream(url: url)
            strings.sorted(by: \.key).map(\.value).map {
                (($0.hasEmptyComment && stripEmptyComments ? [] : [$0.comment]) + [#""\#($0.key)" = "\#($0.value)";"#, "\n"]).joined(separator: "\n")
            }
                .joined()
                .write(to: &stream)
        }

    }

    private struct LocalizedString {

        static var emptyComment: String { "/* No comment provided by engineer. */" }

        var comment: String
        var key: String
        var value: String

        var hasEmptyComment: Bool {
            comment == type(of: self).emptyComment
        }

    }


    private class StringsParser {

        enum Error: Swift.Error {
            case malformedFile(encountered: [String: LocalizedString])
            case unexpectedToken
            case missingToken
        }

        func parse(file url: URL) throws -> [String: LocalizedString] {
            var strings = [String: LocalizedString]()
            var fileContents = try String(contentsOf: url)
            var comments = [String]()
            while fileContents.count > 0 {
                if fileContents.hasPrefix("/*") {
                    do {
                        try comments.append(parseComment(from: &fileContents))
                    } catch {
                        throw Error.malformedFile(encountered: strings)
                    }
                } else if fileContents.hasPrefix("\"") {
                    do {
                        let localizedString = try parseLocalizedString(from: &fileContents, with: comments)
                        strings[localizedString.key] = localizedString
                        comments.removeAll()
                    } catch {
                        throw Error.malformedFile(encountered: strings)
                    }
                } else if fileContents.hasWhitespacePrefix {
                    fileContents.removeFirst()
                } else {
                    throw Error.malformedFile(encountered: strings)
                }
            }
            return strings
        }

        private func parseComment(from fileContents: inout String) throws -> String {
            var comment = ""
            try expect(token: "/*", in: &fileContents)
            while fileContents.occupiedWithoutPrefix("*/") {
                comment.append(fileContents.removeFirst())
            }
            if fileContents.count == 0 { throw Error.missingToken }
            fileContents = String(fileContents.dropFirst(2))
            return comment
        }

        private func parseLocalizedString(from fileContents: inout String, with comments: [String]) throws -> LocalizedString {
            var key = ""
            var value = ""
            try expect(token: "\"", in: &fileContents)
            while fileContents.occupiedWithoutPrefix("\"") {
                key.append(fileContents.removeFirst())
            }
            if fileContents.count == 0 { throw Error.missingToken }
            fileContents.removeFirst()
            try expect(token: "=", in: &fileContents)
            try expect(token: "\"", in: &fileContents)
            while fileContents.occupiedWithoutPrefix("\"") {
                value.append(fileContents.removeFirst())
            }
            if fileContents.count == 0 { throw Error.missingToken }
            fileContents.removeFirst()
            try expect(token: ";", in: &fileContents)
            return LocalizedString(comment: "/*\(comments.joined())*/", key: key, value: value)
        }

        private func expect(token: String, in string: inout String) throws {
            while string.occupiedWithoutPrefix(token) {
                if string.hasWhitespacePrefix { string.removeFirst() }
                else { throw Error.unexpectedToken }
            }
            if string.count == 0 { throw Error.missingToken }
            string = String(string.dropFirst(token.count))
        }

    }

}
