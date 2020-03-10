import SwiftSyntax

protocol SyntaxElement {
    func resolve() -> Syntax
    func resolve(leadingTrivia: Trivia) -> Syntax
    func resolve(trailingTrivia: Trivia) -> Syntax
    func resolve(leadingTrivia: Trivia, trailingTrivia: Trivia) -> Syntax
}

extension SyntaxElement {

    func resolve() -> Syntax {
        resolve(leadingTrivia: [], trailingTrivia: [])
    }

    func resolve(leadingTrivia: Trivia) -> Syntax {
        resolve(leadingTrivia: leadingTrivia, trailingTrivia: [])
    }

    func resolve(trailingTrivia: Trivia) -> Syntax {
        resolve(leadingTrivia: [], trailingTrivia: trailingTrivia)
    }

}

@_functionBuilder struct SyntaxBuilder {

    static func buildBlock(_ elements: SyntaxElement...) -> [SyntaxElement] {
        elements
    }

}
