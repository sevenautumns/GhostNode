import CoreGraphics
import Foundation

extension Point {
    nonisolated func applying(_ m: CGAffineTransform) -> Point {
        Point(CGPoint(x: x, y: y).applying(m))
    }
}

extension Geometry {
    nonisolated func applying(_ m: CGAffineTransform) -> Geometry {
        Geometry(
            topLeft: topLeft.applying(m),
            topRight: topRight.applying(m),
            bottomLeft: bottomLeft.applying(m),
            bottomRight: bottomRight.applying(m)
        )
    }
}

extension OCRWord {
    nonisolated func applying(_ m: CGAffineTransform) -> OCRWord {
        OCRWord(text: text, geometry: geometry.applying(m), direction: direction)
    }
}

extension OCRLine {
    nonisolated func applying(_ m: CGAffineTransform) -> OCRLine {
        OCRLine(
            text: text,
            geometry: geometry.applying(m),
            words: words.map { $0.applying(m) },
            direction: direction
        )
    }
}

extension OCRParagraph {
    nonisolated func applying(_ m: CGAffineTransform) -> OCRParagraph {
        OCRParagraph(
            text: text,
            geometry: geometry.applying(m),
            lines: lines.map { $0.applying(m) }
        )
    }
}

extension OCRResult {
    nonisolated func applying(_ m: CGAffineTransform) -> OCRResult {
        OCRResult(
            fullTranscript: fullTranscript,
            paragraphs: paragraphs.map { $0.applying(m) },
            words: words.map { $0.applying(m) }
        )
    }
}
