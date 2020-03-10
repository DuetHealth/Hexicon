import SwiftSyntax

extension FunctionParameterSyntax {

    var isWildcard: Bool {
        (firstName?.withoutTrivia()).map(String.init(describing:)) == String(describing: SyntaxFactory.makeWildcardKeyword())
    }

}
