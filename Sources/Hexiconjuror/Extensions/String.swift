import Foundation

extension String {

    var hasWhitespacePrefix: Bool {
        first.flatMap { $0.unicodeScalars }
            .flatMap { $0.count == 1 ? $0.first : nil }
            .map(CharacterSet.whitespacesAndNewlines.contains) ?? false
    }

    func occupiedWithoutPrefix(_ prefix: String) -> Bool {
        !hasPrefix(prefix) && count > 0
    }

}
