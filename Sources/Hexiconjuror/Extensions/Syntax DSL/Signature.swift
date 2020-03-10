import SwiftSyntax

struct Signature: SyntaxElement {

    private var children: [SyntaxElement]

    init(@SyntaxBuilder children: () -> [SyntaxElement]) {
        self.children = children()
    }

    func resolve(leadingTrivia: Trivia, trailingTrivia: Trivia) -> Syntax {
        let resolvedChildren = children.map { $0.resolve() }
        let parameters = resolvedChildren.compactMap { $0.as(FunctionParameterSyntax.self) }
        let parameterList = resolvedChildren.first(as: ParameterClauseSyntax.self) ?? ParameterClauseSyntax { builder in
            builder.useLeftParen(SyntaxFactory.makeLeftParenToken())
            parameters.forEach { builder.addParameter($0) }
            builder.useRightParen(SyntaxFactory.makeRightParenToken(trailingTrivia: .space))
        }
        let returnClause = resolvedChildren.first(as: ReturnClauseSyntax.self)
        return FunctionSignatureSyntax { builder in
            builder.useInput(parameterList)
            returnClause.map { builder.useOutput($0) }
        }
            .erased()
    }

}
