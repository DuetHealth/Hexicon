import SwiftSyntax

struct TypeAnnotation: SyntaxElement {

    var type: String

    init(_ type: String) {
        self.type = type
    }


    init<T>(_ type: T.Type) {
        self.type = String(describing: type)
    }

    func resolve(leadingTrivia: Trivia, trailingTrivia: Trivia) -> Syntax {
        TypeAnnotationSyntax { builder in
            builder.useColon(SyntaxFactory.makeColonToken(trailingTrivia: .space))
            builder.useType(SyntaxFactory.makeTypeIdentifier(type, trailingTrivia: trailingTrivia))
        }
            .erased()
    }

}
