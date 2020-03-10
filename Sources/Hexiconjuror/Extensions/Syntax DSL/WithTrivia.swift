import SwiftSyntax

fileprivate struct WithTrivia<Element: SyntaxElement>: SyntaxElement {

    var leading: Trivia
    var trailing: Trivia
    var element: Element

    func resolve(leadingTrivia: Trivia, trailingTrivia: Trivia) -> Syntax {
        element.resolve(leadingTrivia: leading + leadingTrivia, trailingTrivia: trailing + trailingTrivia)
    }

}

extension SyntaxElement {

    func trivia(leading: Trivia = [], trailing: Trivia = []) -> some SyntaxElement {
        WithTrivia<Self>(leading: leading, trailing: trailing, element: self)
    }

    func trivia(leading: TriviaPiece...) -> some SyntaxElement {
        WithTrivia<Self>(leading: Trivia(pieces: leading), trailing: [], element: self)
    }

    func trivia(trailing: TriviaPiece...) -> some SyntaxElement {
        WithTrivia<Self>(leading: [], trailing: Trivia(pieces: trailing), element: self)
    }

}
