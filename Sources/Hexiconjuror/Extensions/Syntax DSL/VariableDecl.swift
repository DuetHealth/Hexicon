import SwiftSyntax

struct VariableDecl: SyntaxElement {

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
        let modifiers = resolvedChildren.compactMap { $0.as(DeclModifierSyntax.self) }
        let mutabilityKeyword = resolvedChildren.first(as: TokenSyntax.self)
        let binding = resolvedChildren.first(as: PatternBindingSyntax.self)
        return DeclSyntax(VariableDeclSyntax { builder in
            modifiers.forEach { builder.addModifier($0) }
            mutabilityKeyword.map { builder.useLetOrVarKeyword($0) }
            binding.map { builder.addBinding($0) }
        })
            .erased()
    }

}
