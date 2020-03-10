import SwiftSyntax

extension SyntaxProtocol {
    func erased() -> Syntax {
        Syntax(self)
    }
}


extension Array where Element == Syntax {

    func first<S: SyntaxProtocol>(as type: S.Type) -> S? {
        first { $0.is(type) }?.as(type)
    }

}

extension SyntaxChildren {

    func first<S: SyntaxProtocol>(as type: S.Type) -> S? {
        first { $0.is(type) }?.as(type)
    }

}
