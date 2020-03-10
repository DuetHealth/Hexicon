import SwiftSyntax

struct Identifier: SyntaxElement {

    var value: String

    init(_ value: String) {
        self.value = value
    }

    func resolve(leadingTrivia: Trivia, trailingTrivia: Trivia) -> Syntax {
        IdentifierPatternSyntax { builder in
            builder.useIdentifier(SyntaxFactory.makeIdentifier(Constants.reservedWords.contains(value) ? "`\(value)`" : value, trailingTrivia: trailingTrivia))
        }
            .erased()
    }

}
