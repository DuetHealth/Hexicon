import Foundation

extension Mirror {

    func enumerateSuperclassMirrors(with closure: (Mirror) -> ()) {
        guard let mirror = superclassMirror else { return }
        closure(mirror)
        mirror.enumerateSuperclassMirrors(with: closure)
    }

}

class EnvironmentObject {

    init() {
        let mirror = Mirror(reflecting: self)
        mirror.children
            .forEach { ($0.value as? _EnvironmentSupplied)?.__environment = self }
        mirror.enumerateSuperclassMirrors {
            $0.children
                .forEach { ($0.value as? _EnvironmentSupplied)?.__environment = self }
        }
    }

    open subscript(_ key: String) -> String? { nil }

}

@propertyWrapper struct EnvironmentVariable<Value>: _EnvironmentSupplied {

    let key: String
    private let converter: (String) -> Value?
    @ParentEnvironment fileprivate var environment: EnvironmentObject

    fileprivate var __environment: EnvironmentObject {
        get { environment }
        nonmutating set { environment = newValue }
    }

    init(_ key: String, via converter: @escaping (String) -> Value) {
        self.key = key
        self.converter = converter
    }

    init(_ key: String, via converter: @escaping (String) -> Value?) {
        self.key = key
        self.converter = converter
    }

    var wrappedValue: Value {
        guard let value = environment[key].flatMap(converter) else {
            print("Could not find xcodebuild environment variable \(key).")
            exit(1)
        }
        return value
    }

}

extension EnvironmentVariable where Value: LosslessStringConvertible {

    init(_ key: String) {
        self.init(key, via: Value.init)
    }

}

fileprivate protocol _EnvironmentSupplied {
    var __environment: EnvironmentObject { get nonmutating set }
}

@propertyWrapper fileprivate class ParentEnvironment {

    fileprivate var value: EnvironmentObject!

    var wrappedValue: EnvironmentObject {
        get {
            guard let value = self.value else {
                fatalError("The value was not provided an Environment. Environment variables should only be declared as members of instances of EnvironmentObject.")
            }
            return value
        }
        set {
            if value != nil { return }
            value = newValue
        }
    }

}
