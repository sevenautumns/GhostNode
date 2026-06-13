import CoreGraphics
import Foundation

nonisolated enum OCRCoordinateMapping {
    static func overlay(
        widthPx: UInt32,
        heightPx: UInt32,
        render: CGAffineTransform
    ) -> CGAffineTransform {
        CGAffineTransform(scaleX: CGFloat(widthPx), y: CGFloat(heightPx))
            .concatenating(render.inverted())
    }

    static func image(
        widthPx: UInt32,
        heightPx: UInt32,
        dpi: Double
    ) -> CGAffineTransform {
        CGAffineTransform(
            scaleX: CGFloat(Double(widthPx) * 72.0 / dpi),
            y: CGFloat(Double(heightPx) * 72.0 / dpi)
        )
    }
}

extension RenderedPagePNG {
    nonisolated var overlayMapping: CGAffineTransform {
        OCRCoordinateMapping.overlay(widthPx: widthPx, heightPx: heightPx, render: transform)
    }

    nonisolated var imageMapping: CGAffineTransform {
        OCRCoordinateMapping.image(widthPx: widthPx, heightPx: heightPx, dpi: dpi)
    }
}

extension ImageBuffer {
    nonisolated var imageMapping: CGAffineTransform {
        OCRCoordinateMapping.image(
            widthPx: UInt32(pixelWidth),
            heightPx: UInt32(pixelHeight),
            dpi: dpi
        )
    }
}

extension OCRedPage {
    nonisolated var overlayOCR: OCRResult? {
        rendered.flatMap { render in ocr?.applying(render.overlayMapping) }
    }

    nonisolated var imageOCR: OCRResult? {
        rendered.flatMap { render in ocr?.applying(render.imageMapping) }
    }
}
