import Foundation

#if canImport(UIKit)
    import UIKit

    typealias PlatformImage = UIImage
#elseif canImport(AppKit)
    import AppKit

    typealias PlatformImage = NSImage
#endif

enum ImageBufferError: Error {
    case encodingFailed
    case invalidImageData
}

nonisolated struct ImageBuffer {
    let image: PlatformImage

    init(image: PlatformImage) {
        self.image = image
    }

    init(data: Data) throws {
        #if canImport(UIKit)
            guard let img = UIImage(data: data) else {
                throw ImageBufferError.invalidImageData
            }
            image = img
        #elseif canImport(AppKit)
            guard let img = NSImage(data: data) else {
                throw ImageBufferError.invalidImageData
            }
            image = img
        #endif
    }

    var dpi: Double {
        300
    }

    var pixelWidth: Int {
        #if canImport(UIKit)
            return Int(image.size.width * image.scale)
        #elseif canImport(AppKit)
            return image.representations.first?.pixelsWide
                ?? Int(image.size.width)
        #endif
    }

    var pixelHeight: Int {
        #if canImport(UIKit)
            return Int(image.size.height * image.scale)
        #elseif canImport(AppKit)
            return image.representations.first?.pixelsHigh
                ?? Int(image.size.height)
        #endif
    }

    var data: Data? {
        #if canImport(UIKit)
            return image.pngData()
        #elseif canImport(AppKit)
            guard let tiff = image.tiffRepresentation,
                  let rep = NSBitmapImageRep(data: tiff)
            else { return nil }
            return rep.representation(using: .png, properties: [:])
        #else
            return nil
        #endif
    }
}
