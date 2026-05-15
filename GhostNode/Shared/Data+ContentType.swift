import Foundation
import ImageIO

nonisolated extension Data {
    var isPDF: Bool {
        starts(with: Data("%PDF-".utf8))
    }

    var isImage: Bool {
        CGImageSourceCreateWithData(self as CFData, nil) != nil
    }
}
