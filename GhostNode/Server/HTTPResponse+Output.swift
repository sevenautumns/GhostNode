import FlyingFox
import Foundation

enum OutputFormat: String {
    case pdf = "application/pdf"
    case json = "application/json"
}

nonisolated extension HTTPResponse {
    static func pdf(_ data: Data) -> HTTPResponse {
        HTTPResponse(
            statusCode: .ok,
            headers: [
                .contentType: OutputFormat.pdf.rawValue,
                .contentLength: "\(data.count)",
            ],
            body: data
        )
    }

    static func json(
        _ value: some Encodable,
        statusCode: HTTPStatusCode = .ok
    ) -> HTTPResponse {
        do {
            let data = try JSONEncoder().encode(value)
            return HTTPResponse(
                statusCode: statusCode,
                headers: [
                    .contentType: OutputFormat.json.rawValue,
                    .contentLength: "\(data.count)",
                ],
                body: data
            )
        } catch {
            return .error(
                message: "Failed to encode response",
                statusCode: .internalServerError
            )
        }
    }

    static func error(message: String, statusCode: HTTPStatusCode) -> HTTPResponse {
        .json(["error": message], statusCode: statusCode)
    }
}
