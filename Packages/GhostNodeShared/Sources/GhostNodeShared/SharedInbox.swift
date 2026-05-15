import Foundation

public enum SharedInboxError: Error {
    case appGroupUnavailable
}

public enum SharedInbox {
    public static let appGroup = "group.de.autumnal.ghostnode"
    public static let scheme = "ghostnode"
    public static let importHost = "import"

    public static var container: URL? {
        FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroup
        )
    }

    public static func deposit(_ data: Data, pathExtension: String) throws -> String {
        guard let container else { throw SharedInboxError.appGroupUnavailable }
        let name = "\(UUID().uuidString).\(pathExtension)"
        try data.write(to: container.appendingPathComponent(name))
        return name
    }

    public static func handoffURL(filenames: [String]) -> URL? {
        var comps = URLComponents()
        comps.scheme = scheme
        comps.host = importHost
        comps.queryItems = [
            URLQueryItem(name: "files", value: filenames.joined(separator: ",")),
        ]
        return comps.url
    }

    public static func drain(from url: URL) -> [URL] {
        guard let container,
              let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let csv = comps.queryItems?
              .first(where: { $0.name == "files" })?.value
        else { return [] }
        return csv.split(separator: ",").map {
            container.appendingPathComponent(String($0))
        }
    }
}
