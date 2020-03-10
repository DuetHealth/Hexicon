import Foundation

typealias RegularExpression = NSRegularExpression

extension RegularExpression {

    func firstMatch(in string: String) -> String? {
        firstMatch(in: string, options: [], range: NSRange(0..<string.count))
            .map { (string as NSString).substring(with: $0.range) }
    }

    func capturedGroups(in string: String) -> [String] {
        matches(in: string, options: [], range: NSRange(0..<string.count))
            .compactMap {
                guard $0.numberOfRanges > 1 else { return nil }
                return (string as NSString).substring(with: $0.range(at: 1))
            }
    }

}
