import SwiftSyntax

extension ModifierListSyntax {

    var isStatic: Bool {
        contains { String(describing: $0.name.withoutTrivia()) == String(describing: SyntaxFactory.makeStaticKeyword()) }
    }

}
