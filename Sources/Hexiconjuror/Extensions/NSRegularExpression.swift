import Foundation

typealias RegularExpression = NSRegularExpression

extension RegularExpression {

    func firstMatch(in string: String) -> String? {
        firstMatch(in: string, options: [], range: NSRange(0..<string.count))
            .map { (string as NSString).substring(with: $0.range) }
    }

    func capturedGroups(in string: String) -> [String] {
        Array(matches(in: string, options: [], range: NSRange(0..<string.count))
            .compactMap { result -> [String]? in
                guard result.numberOfRanges > 1 else { return nil }
                return (1..<result.numberOfRanges).map {
                    (string as NSString).substring(with: result.range(at: $0))
                }
            }
            .joined())
    }

}
