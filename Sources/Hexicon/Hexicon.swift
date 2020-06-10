import Foundation

public class Localized {

    public class Strings: LocalizationNamespace { }

    private init() { }

}

@dynamicMemberLookup open class LocalizationNamespace {

    public class var bundle: Bundle {
        Bundle(for: self)
    }

    private init() { }

    public static subscript(dynamicMember key: String) -> String {
        fatalError("This call should never be reached.")
    }

    public static subscript(dynamicMember functionName: String) -> FormattedStringPlaceholder {
        fatalError("This call should never be reached.")
    }

}

@dynamicCallable public struct FormattedStringPlaceholder {

    public func dynamicallyCall(withKeywordArguments arguments: KeyValuePairs<String, Any>) -> String {
        fatalError("This call should never be reached.")
    }

    public func dynamicallyCall(withArguments arguments: [Any]) -> String {
        fatalError("This call should never be reached.")
    }

}
