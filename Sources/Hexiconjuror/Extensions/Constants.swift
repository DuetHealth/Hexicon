import Hexicon
import SwiftSyntax

enum Constants {

    static var rootNamespace: String {
        String(reflecting: Localized.Strings.self).components(separatedBy: ".").dropFirst().joined(separator: ".")
    }

    static let reservedWords: Set<String> = {
        [
            String(describing: SyntaxFactory.makeClassKeyword()),
            String(describing: SyntaxFactory.makeDeinitKeyword()),
            String(describing: SyntaxFactory.makeEnumKeyword()),
            String(describing: SyntaxFactory.makeExtensionKeyword()),
            String(describing: SyntaxFactory.makeFuncKeyword()),
            String(describing: SyntaxFactory.makeImportKeyword()),
            String(describing: SyntaxFactory.makeInitKeyword()),
            String(describing: SyntaxFactory.makeInternalKeyword()),
            String(describing: SyntaxFactory.makeLetKeyword()),
            String(describing: SyntaxFactory.makeOperatorKeyword()),
            String(describing: SyntaxFactory.makePrivateKeyword()),
            String(describing: SyntaxFactory.makeProtocolKeyword()),
            String(describing: SyntaxFactory.makePublicKeyword()),
            String(describing: SyntaxFactory.makeStaticKeyword()),
            String(describing: SyntaxFactory.makeStructKeyword()),
            String(describing: SyntaxFactory.makeSubscriptKeyword()),
            String(describing: SyntaxFactory.makeTypealiasKeyword()),
            String(describing: SyntaxFactory.makeVarKeyword()),
            String(describing: SyntaxFactory.makeBreakKeyword()),
            String(describing: SyntaxFactory.makeCaseKeyword()),
            String(describing: SyntaxFactory.makeContinueKeyword()),
            String(describing: SyntaxFactory.makeDefaultKeyword()),
            String(describing: SyntaxFactory.makeDoKeyword()),
            String(describing: SyntaxFactory.makeElseKeyword()),
            String(describing: SyntaxFactory.makeFallthroughKeyword()),
            String(describing: SyntaxFactory.makeForKeyword()),
            String(describing: SyntaxFactory.makeIfKeyword()),
            String(describing: SyntaxFactory.makeInKeyword()),
            String(describing: SyntaxFactory.makeReturnKeyword()),
            String(describing: SyntaxFactory.makeSwitchKeyword()),
            String(describing: SyntaxFactory.makeWhereKeyword()),
            String(describing: SyntaxFactory.makeWhileKeyword()),
            String(describing: SyntaxFactory.makeAsKeyword()),
            String(describing: SyntaxFactory.makeFalseKeyword()),
            String(describing: SyntaxFactory.makeIsKeyword()),
            String(describing: SyntaxFactory.makeNilKeyword()),
            String(describing: SyntaxFactory.makeSelfKeyword()),
            String(describing: SyntaxFactory.makeSuperKeyword()),
            String(describing: SyntaxFactory.makeTrueKeyword()),
        ]
    }()

}
