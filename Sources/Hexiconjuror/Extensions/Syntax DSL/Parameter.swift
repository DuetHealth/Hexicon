import SwiftSyntax

struct Parameter: SyntaxElement {

    var label: String?
    var name: String?
    var typeName: String
    var isTrailing = false

    init<T>(label: String, name: String? = nil, type: T.Type) {
        self.label = label
        self.name = name
        typeName = String(describing: type)
    }

    init<T>(name: String, type: T.Type) {
        self.name = name
        typeName = String(describing: type)
    }

    func resolve(leadingTrivia: Trivia, trailingTrivia: Trivia) -> Syntax {
        FunctionParameterSyntax { builder in
            builder.useFirstName(label.map {
                SyntaxFactory.makeIdentifier($0, trailingTrivia: name != nil ? .space : [])
            } ?? SyntaxFactory.makeWildcardKeyword(trailingTrivia: .space))
            name.map { builder.useSecondName(SyntaxFactory.makeIdentifier($0)) }
            builder.useColon(SyntaxFactory.makeColonToken(trailingTrivia: .space))
            builder.useType(SyntaxFactory.makeTypeIdentifier(typeName))
            if !isTrailing {
                builder.useTrailingComma(SyntaxFactory.makeCommaToken(trailingTrivia: .space))
            }
        }
            .erased()
    }

}

struct ParameterList: SyntaxElement {

    private var parameters: [Parameter]

    init(_ parameters: () -> [Parameter]) {
        self.init(parameters())
    }

    init(_ parameters: [Parameter] = []) {
        self.parameters = parameters
        self.parameters[parameters.count - 1].isTrailing = true
    }

    func resolve(leadingTrivia: Trivia, trailingTrivia: Trivia) -> Syntax {
        ParameterClauseSyntax { builder in
            builder.useLeftParen(SyntaxFactory.makeLeftParenToken())
            parameters.forEach { builder.addParameter($0.resolve().as(FunctionParameterSyntax.self)!) }
            builder.useRightParen(SyntaxFactory.makeRightParenToken(trailingTrivia: .space))
        }
            .erased()
    }

}
