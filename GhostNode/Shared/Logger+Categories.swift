import os

extension Logger {
    private nonisolated static let subsystem = "de.autumnal.ghostnode"

    nonisolated static let ocr = Logger(subsystem: subsystem, category: "ocr")
    nonisolated static let server = Logger(subsystem: subsystem, category: "server")
}
