import SwiftSyntax

struct Var: SyntaxElement {

    func resolve(leadingTrivia: Trivia, trailingTrivia: Trivia) -> Syntax {
        SyntaxFactory.makeVarKeyword(leadingTrivia: leadingTrivia, trailingTrivia: trailingTrivia).erased()
    }

}

