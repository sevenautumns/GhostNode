import Foundation
import Vision

nonisolated struct Point: Codable, Equatable {
    let x: Double
    let y: Double
}

extension Point {
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, *)
    nonisolated init(from point: NormalizedPoint) {
        self.init(
            x: point.x,
            y: point.y
        )
    }

    nonisolated init(_ cgPoint: CGPoint) {
        self.init(x: Double(cgPoint.x), y: Double(cgPoint.y))
    }
}

nonisolated struct Geometry: Codable, Equatable {
    let topLeft: Point
    let topRight: Point
    let bottomLeft: Point
    let bottomRight: Point
}

extension Geometry {
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, *)
    nonisolated init(from quad: QuadrilateralProviding) {
        self.init(
            topLeft: Point(from: quad.topLeft),
            topRight: Point(from: quad.topRight),
            bottomLeft: Point(from: quad.bottomLeft),
            bottomRight: Point(from: quad.bottomRight)
        )
    }

    @available(iOS 26.0, macOS 26.0, tvOS 26.0, *)
    nonisolated init?(candidate: RecognizedText, range: Range<String.Index>) {
        guard let box = candidate.boundingBox(for: range) else { return nil }
        self.init(from: box)
    }

    nonisolated init(from observation: VNRectangleObservation) {
        self.init(
            topLeft: Point(observation.topLeft),
            topRight: Point(observation.topRight),
            bottomLeft: Point(observation.bottomLeft),
            bottomRight: Point(observation.bottomRight)
        )
    }
}

nonisolated enum Direction: String, Codable {
    case leftToRight
    case rightToLeft
    case topToBottom
}

extension Direction {
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, *)
    nonisolated init(from direction: RecognizedTextObservation.Direction?) {
        switch direction {
        case .rightToLeft: self = .rightToLeft
        case .topToBottom: self = .topToBottom
        default: self = .leftToRight
        }
    }
}

nonisolated struct OCRWord: Codable {
    let text: String
    let geometry: Geometry
    let direction: Direction
}

extension OCRWord {
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, *)
    nonisolated init(from observation: RecognizedTextObservation) {
        self.init(
            text: observation.transcript,
            geometry: Geometry(from: observation),
            direction: Direction(from: observation.textDirection)
        )
    }

    @available(iOS 26.0, macOS 26.0, tvOS 26.0, *)
    nonisolated init?(candidate: RecognizedText, substring: Substring, direction: Direction) {
        guard
            let box = candidate.boundingBox(
                for: substring.startIndex ..< substring.endIndex
            )
        else {
            return nil
        }

        self.init(
            text: String(substring),
            geometry: Geometry(from: box),
            direction: direction
        )
    }

    nonisolated init?(
        candidate: VNRecognizedText,
        substring: Substring,
        direction: Direction
    ) {
        guard
            let box = try? candidate.boundingBox(
                for: substring.startIndex ..< substring.endIndex
            )
        else {
            return nil
        }

        self.init(
            text: String(substring),
            geometry: Geometry(from: box),
            direction: direction
        )
    }

    nonisolated func merging(with next: OCRWord) -> OCRWord {
        OCRWord(
            text: text + " " + next.text,
            geometry: geometry,
            direction: direction
        )
    }
}

nonisolated struct OCRLine: Codable {
    let text: String
    let geometry: Geometry
    let words: [OCRWord]
    let direction: Direction
}

extension OCRLine {
    nonisolated static func merging(_ words: [OCRWord]) -> [OCRWord] {
        words.reduce(into: []) { result, current in
            if let last = result.last, last.geometry == current.geometry {
                result[result.count - 1] = last.merging(with: current)
            } else {
                result.append(current)
            }
        }
    }

    nonisolated init(
        text: String,
        geometry: Geometry,
        direction: Direction,
        wordFor: (Substring) -> OCRWord?
    ) {
        let raw = text.split(separator: " ").compactMap(wordFor)
        self.init(
            text: text,
            geometry: geometry,
            words: Self.merging(raw),
            direction: direction
        )
    }

    @available(iOS 26.0, macOS 26.0, tvOS 26.0, *)
    nonisolated init(from observation: RecognizedTextObservation) {
        let direction = Direction(from: observation.textDirection)
        let geometry = Geometry(from: observation)
        let text = observation.transcript

        guard let candidate = observation.topCandidates(1).first else {
            self.init(text: text, geometry: geometry, words: [], direction: direction)
            return
        }
        self.init(text: text, geometry: geometry, direction: direction) {
            OCRWord(candidate: candidate, substring: $0, direction: direction)
        }
    }

    nonisolated init(from observation: VNRecognizedTextObservation) {
        let direction: Direction = .leftToRight
        let geometry = Geometry(from: observation)
        let candidate = observation.topCandidates(1).first
        let text = candidate?.string ?? ""

        guard let candidate else {
            self.init(text: text, geometry: geometry, words: [], direction: direction)
            return
        }
        self.init(text: text, geometry: geometry, direction: direction) {
            OCRWord(candidate: candidate, substring: $0, direction: direction)
        }
    }
}

nonisolated struct OCRParagraph: Codable {
    let text: String
    let geometry: Geometry
    let lines: [OCRLine]
}

extension OCRParagraph {
    @available(iOS 26.0, macOS 26.0, tvOS 26.0, *)
    nonisolated init(from paragraph: DocumentObservation.Container.Text) {
        self.init(
            text: paragraph.transcript,
            geometry: Geometry(from: paragraph.boundingRegion.boundingQuad),
            lines: paragraph.lines.map(OCRLine.init)
        )
    }

    nonisolated init(lines: [OCRLine]) {
        text = lines.map(\.text).joined(separator: "\n")

        let topLeft = Point(
            x: lines.map(\.geometry.topLeft.x).min() ?? 0,
            y: lines.map(\.geometry.topLeft.y).max() ?? 0
        )
        let topRight = Point(
            x: lines.map(\.geometry.topRight.x).max() ?? 0,
            y: lines.map(\.geometry.topRight.y).max() ?? 0
        )
        let bottomLeft = Point(
            x: lines.map(\.geometry.bottomLeft.x).min() ?? 0,
            y: lines.map(\.geometry.bottomLeft.y).min() ?? 0
        )
        let bottomRight = Point(
            x: lines.map(\.geometry.bottomRight.x).max() ?? 0,
            y: lines.map(\.geometry.bottomRight.y).min() ?? 0
        )

        geometry = Geometry(
            topLeft: topLeft,
            topRight: topRight,
            bottomLeft: bottomLeft,
            bottomRight: bottomRight
        )
        self.lines = lines
    }
}

nonisolated struct OCRResult: Codable {
    let fullTranscript: String
    let paragraphs: [OCRParagraph]
    let words: [OCRWord]
}

struct OCRProgress: Equatable {
    let completed: Int
    let total: Int

    var fraction: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }
}
