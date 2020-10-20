import Foundation

extension Sequence {

    func sorted<Value: Comparable>(by keyPath: KeyPath<Element, Value>) -> [Element] {
        sorted { $0[keyPath: keyPath] < $1[keyPath: keyPath] }
    }

}
