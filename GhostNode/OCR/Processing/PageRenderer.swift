import CoreGraphics
import Foundation
import ImageIO
import PDFKit
import UniformTypeIdentifiers

struct RenderedPagePNG {
    let pngData: Data
    let widthPx: UInt32
    let heightPx: UInt32
    let dpi: Double
}

nonisolated enum PageRenderer {
    static func renderPNG(_ page: PDFPage, dpi: CGFloat = 300) -> RenderedPagePNG? {
        autoreleasepool { () -> RenderedPagePNG? in
            let scale = dpi / 72.0
            let mediaBox = page.bounds(for: .mediaBox)
            let widthPx = Int((mediaBox.width * scale).rounded())
            let heightPx = Int((mediaBox.height * scale).rounded())
            guard widthPx > 0, heightPx > 0 else { return nil }

            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
            guard
                let ctx = CGContext(
                    data: nil,
                    width: widthPx,
                    height: heightPx,
                    bitsPerComponent: 8,
                    bytesPerRow: widthPx * 4,
                    space: colorSpace,
                    bitmapInfo: bitmapInfo
                )
            else { return nil }

            ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
            ctx.fill(CGRect(x: 0, y: 0, width: widthPx, height: heightPx))
            ctx.scaleBy(x: scale, y: scale)
            page.draw(with: .mediaBox, to: ctx)

            guard let cgImage = ctx.makeImage() else { return nil }

            let out = NSMutableData()
            guard
                let dest = CGImageDestinationCreateWithData(
                    out,
                    UTType.png.identifier as CFString,
                    1,
                    nil
                )
            else { return nil }
            CGImageDestinationAddImage(dest, cgImage, nil)
            guard CGImageDestinationFinalize(dest) else { return nil }

            return RenderedPagePNG(
                pngData: out as Data,
                widthPx: UInt32(widthPx),
                heightPx: UInt32(heightPx),
                dpi: Double(dpi)
            )
        }
    }
}
