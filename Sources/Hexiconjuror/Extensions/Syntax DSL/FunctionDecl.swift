import SwiftSyntax

struct FunctionDecl: SyntaxElement {

    private var children: [SyntaxElement]

    init(@SyntaxBuilder children: () -> [SyntaxElement]) {
        self.children = children()
    }

    func resolve(leadingTrivia: Trivia, trailingTrivia: Trivia) -> Syntax {
        let resolvedChildren: [Syntax]
        switch children.count {
        case 0:
            resolvedChildren = []
        case 1:
            resolvedChildren = [children.first!.resolve(leadingTrivia: leadingTrivia, trailingTrivia: trailingTrivia)]
        default:
            resolvedChildren = [children.first!.resolve(leadingTrivia: leadingTrivia)]
                + children.dropFirst().dropLast().map { $0.resolve() }
                + [children.last!.resolve(leadingTrivia: leadingTrivia, trailingTrivia: trailingTrivia)]
        }
        return FunctionDeclSyntax { builder in
            resolvedChildren.compactMap { $0.as(DeclModifierSyntax.self) }.forEach {
                builder.addModifier($0)
            }
            builder.useFuncKeyword(SyntaxFactory.makeFuncKeyword(trailingTrivia: .space))
            resolvedChildren.first(as: IdentifierPatternSyntax.self).map { builder.useIdentifier($0.identifier) }
            resolvedChildren.first(as: FunctionSignatureSyntax.self).map { builder.useSignature($0) }
            resolvedChildren.first(as: CodeBlockSyntax.self).map { builder.useBody($0) }
        }
            .erased()
    }

}
