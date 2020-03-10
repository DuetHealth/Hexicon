import Foundation

struct FileOutputStream: TextOutputStream {

    let encoding: String.Encoding
    private let fileHandle: FileHandle

    init(url: URL, encoding: String.Encoding = .utf8) throws {
        self.fileHandle = try FileHandle(forWritingTo: url)
        self.encoding = encoding
    }

    func write(_ string: String) {
        string.data(using: encoding).map(fileHandle.write)
    }
}
