import Foundation

enum NetworkInterfaces {
    nonisolated static func localHosts() -> [String] {
        var hosts: [String] = []

        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return [] }
        defer { freeifaddrs(ifaddr) }

        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }

            guard let interface = ptr?.pointee else { continue }
            guard let addrPtr = interface.ifa_addr else { continue }
            let family = addrPtr.pointee.sa_family
            guard family == UInt8(AF_INET) || family == UInt8(AF_INET6) else {
                continue
            }
            let name = String(cString: interface.ifa_name)
            guard name != "lo0" else { continue }

            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            let rc = getnameinfo(
                addrPtr,
                socklen_t(addrPtr.pointee.sa_len),
                &hostname,
                socklen_t(hostname.count),
                nil,
                0,
                NI_NUMERICHOST
            )
            guard rc == 0 else { continue }

            let raw = hostname.withUnsafeBufferPointer { buf in
                buf.baseAddress.map { String(cString: $0) } ?? ""
            }
            let address = raw.split(separator: "%", maxSplits: 1)
                .first.map(String.init) ?? raw

            if family == UInt8(AF_INET6),
               address.lowercased().hasPrefix("fe80")
            {
                continue
            }

            hosts.append(family == UInt8(AF_INET6) ? "[\(address)]" : address)
        }

        return hosts
    }
}
