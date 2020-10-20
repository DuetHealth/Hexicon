import Foundation

func mutate<T>(_ value: T, mutator: (inout T) -> ()) -> T {
    var copy = value
    mutator(&copy)
    return copy
}
