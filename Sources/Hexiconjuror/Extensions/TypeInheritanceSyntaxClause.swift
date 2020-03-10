import SwiftSyntax

extension TypeInheritanceClauseSyntax {

    func inherits<T>(_ type: T.Type) -> Bool {
        inheritedTypeCollection.contains { String(describing: $0.withoutTrivia()) == String(describing: type) }
    }

}
