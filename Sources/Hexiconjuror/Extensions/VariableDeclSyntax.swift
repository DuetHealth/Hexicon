import SwiftSyntax

extension VariableDeclSyntax {

    var variableName: String {
        guard let value = children.last?.children.first(as: PatternBindingSyntax.self)?.children.first(as: IdentifierPatternSyntax.self)?.identifier.text else {
            fatalError("The expected structure of a variable declaration has changed!")
        }
        return value
    }

}
