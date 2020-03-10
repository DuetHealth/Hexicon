import SwiftSyntax

extension MemberDeclListSyntax {

    mutating func remove(childAt index: Int) {
        self = removing(childAt: index)
    }

    mutating func append(_ syntax: MemberDeclListItemSyntax) {
        self = appending(syntax)
    }

}

extension MemberDeclListItemSyntax {

    init<D: DeclSyntaxProtocol>(_ decl: D) {
        self.init { $0.useDecl(DeclSyntax(decl)) }
    }

}

