import SwiftSyntax

struct Static: SyntaxElement {

    func resolve(leadingTrivia: Trivia, trailingTrivia: Trivia) -> Syntax {
        DeclModifierSyntax { builder in builder.useDetail(SyntaxFactory.makeStaticKeyword(leadingTrivia: leadingTrivia, trailingTrivia: trailingTrivia)) }
            .erased()
    }

}
