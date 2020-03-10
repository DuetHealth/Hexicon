import SwiftSyntax

struct Unknown: SyntaxElement {

    var text: String

    init(_ text: String) {
        self.text = text
    }

    func resolve(leadingTrivia: Trivia, trailingTrivia: Trivia) -> Syntax {
        SyntaxFactory.makeUnknown(text, leadingTrivia: leadingTrivia, trailingTrivia: trailingTrivia).erased()
    }

}
