import SwiftSyntax

struct Pattern: SyntaxElement {

    private var children: [SyntaxElement]

    init(@SyntaxBuilder children: () -> [SyntaxElement]) {
        self.children = children()
    }

    func resolve(leadingTrivia: Trivia, trailingTrivia: Trivia) -> Syntax {
        let resolvedChildren = children.map { $0.resolve(leadingTrivia: leadingTrivia, trailingTrivia: trailingTrivia) }
        let identifier = resolvedChildren.first(as: IdentifierPatternSyntax.self)
        let typeAnnotation = resolvedChildren.first(as: TypeAnnotationSyntax.self)
        let codeBlock = resolvedChildren.first(as: CodeBlockSyntax.self)
        return PatternBindingSyntax { builder in
            identifier.map { builder.usePattern(PatternSyntax($0)) }
            typeAnnotation.map { builder.useTypeAnnotation($0) }
            codeBlock.map { builder.useAccessor(Syntax($0)) }
        }
            .erased()
    }

}
