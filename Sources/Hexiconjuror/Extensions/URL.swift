import Foundation

extension URL {

    var resourceName: String {
        lastPathComponent.components(separatedBy: ".").first ?? lastPathComponent
    }

}
