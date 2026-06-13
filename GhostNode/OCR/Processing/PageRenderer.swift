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
    let transform: CGAffineTransform
}

nonisolated enum PageRenderer {
    static func renderPNG(_ page: PDFPage, dpi: CGFloat = 300) -> RenderedPagePNG? {
        autoreleasepool { () -> RenderedPagePNG? in
            let scale = dpi / 72.0
            guard let cgPage = page.pageRef else { return nil }
            let box = cgPage.getBoxRect(.mediaBox)
            let displayed = cgPage.rotationAngle % 180 == 0
                ? box.size
                : CGSize(width: box.height, height: box.width)
            let widthPx = Int((displayed.width * scale).rounded())
            let heightPx = Int((displayed.height * scale).rounded())
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

            let pointRect = CGRect(origin: .zero, size: displayed)
            let drawing = cgPage.getDrawingTransform(
                .mediaBox,
                rect: pointRect,
                rotate: 0,
                preserveAspectRatio: true
            )
            let transform = drawing.concatenating(CGAffineTransform(scaleX: scale, y: scale))

            ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
            ctx.fill(CGRect(x: 0, y: 0, width: widthPx, height: heightPx))
            ctx.concatenate(transform)
            ctx.drawPDFPage(cgPage)

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
                dpi: Double(dpi),
                transform: transform
            )
        }
    }
}
