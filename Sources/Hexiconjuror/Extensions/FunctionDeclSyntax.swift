import SwiftSyntax

extension FunctionDeclSyntax {

    var functionName: String {
        identifier.withoutTrivia().text
    }

    var argumentLabels: FunctionInvocation.Arguments? {
        let parameterList = signature.input.parameterList
        guard parameterList.count > 0 else { return .empty }
        let labeled = parameterList.first?.firstName != nil
        guard parameterList.allSatisfy({ labeled == ($0.firstName != nil) }) else { return nil }
        return labeled ? .labeled(parameterList.map { $0.firstName!.text }) : .unlabeled(count: parameterList.count)
    }

}
