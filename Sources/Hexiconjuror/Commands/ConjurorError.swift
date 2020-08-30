import Foundation

enum ConjurorError: String, Error {
    case invalidArguments
    case invalidDiff = "The supplied diff is not valid"
}
