import Foundation

extension Result where Failure == Error {

    func flatMapCatching<NewSuccess>(_ transform: (Success) throws -> (NewSuccess)) -> Result<NewSuccess, Failure> {
        flatMap { success in
            Result<NewSuccess, Failure> { try transform(success) }
        }
    }

}
