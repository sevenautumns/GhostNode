import Foundation

nonisolated enum OCRJSONEncoder {
    static func encode(_ ocr: OCRResult?) throws -> String? {
        guard let ocr else { return nil }
        let data = try JSONEncoder().encode(ocr)
        return String(decoding: data, as: UTF8.self)
    }
}
