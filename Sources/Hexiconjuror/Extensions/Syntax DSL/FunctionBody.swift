import SwiftSyntax

struct FunctionBody: SyntaxElement {

    private var children: [SyntaxElement]

    init(@SyntaxBuilder children: () -> [SyntaxElement]) {
        self.children = children()
    }

    func resolve(leadingTrivia: Trivia, trailingTrivia: Trivia) -> Syntax {
        let resolvedChildren = children.map { $0.resolve(leadingTrivia: leadingTrivia.spaces + .spaces(4), trailingTrivia: trailingTrivia) }
        return CodeBlockSyntax { builder in
            builder.useLeftBrace(SyntaxFactory.makeLeftBraceToken(trailingTrivia: .newlines(1)))
            resolvedChildren.forEach { child in
                builder.addStatement(CodeBlockItemSyntax { $0.useItem(child) })
            }
            builder.useRightBrace(SyntaxFactory.makeRightBraceToken(leadingTrivia: .newlines(1) + leadingTrivia.spaces, trailingTrivia: trailingTrivia))
        }
            .erased()
    }

}
