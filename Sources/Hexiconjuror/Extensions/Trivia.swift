import SwiftSyntax

extension Trivia {

    static var space: Trivia {
        .spaces(1)
    }

    var spaces: Trivia {
        first { piece in
            switch piece {
            case .spaces: return true
            default: return false
            }
        }.map { Trivia(pieces: [$0]) } ?? []
    }

}
