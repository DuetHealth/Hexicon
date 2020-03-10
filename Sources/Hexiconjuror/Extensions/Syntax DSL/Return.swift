import SwiftSyntax

struct Return: SyntaxElement {

    var typeName: String

    init<T>(_ returnType: T.Type) {
        typeName = String(describing: returnType)
    }

    func resolve(leadingTrivia: Trivia, trailingTrivia: Trivia) -> Syntax {
        ReturnClauseSyntax { builder in
            builder.useArrow(SyntaxFactory.makeArrowToken(trailingTrivia: .space))
            builder.useReturnType(SyntaxFactory.makeTypeIdentifier(typeName, trailingTrivia: .space))
        }
            .erased()
    }

}
