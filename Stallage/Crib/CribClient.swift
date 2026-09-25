import Foundation

/// Role: Crib. Typed transport failures. This product has no remote catalog; contact is a Settings link.
enum CribWireFault: Error, Equatable, Sendable {
    case notFound
    case decoding
    case transport
    case cancelled
    case invalidResponse
}

/// Role: Crib. One HTTP hop. Injected so tests never leave the process.
protocol CribCarrying: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

/// Role: Crib. URLSession hop, 15 s timeout, app User-Agent on every request.
struct CribSession: CribCarrying {
    let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 15
        configuration.httpAdditionalHeaders = ["User-Agent": CribClient.userAgent]
        self.session = URLSession(configuration: configuration)
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}

/// Role: Crib. DTO that mirrors a JSON object exactly. Never decoded into Crib or Tag.
struct CribProbeDTO: Decodable, Sendable {
    var ok: Bool
}

/// Role: Crib. Owns the session. No required remote catalog. cgi search.pl stays dark. Contact URL is a Settings link, not fetched into a WebView.
actor CribClient {
    static let userAgent = "Stallage/1.0 (iOS; +https://stallage-crib.pro)"
    /// Programmer constant; the domain string is fixed in SPEC.md.
    static let contactURL = URL(string: "https://stallage-crib.pro/contact-us")!

    private let carrier: any CribCarrying

    init(carrier: any CribCarrying) {
        self.carrier = carrier
    }

    init() {
        self.carrier = CribSession()
    }

    func getJSON<DTO: Decodable & Sendable>(_ type: DTO.Type, from url: URL) async throws -> DTO {
        try Task.checkCancellation()
        let body = try await fetch(request(for: url))
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        do {
            return try decoder.decode(DTO.self, from: body)
        } catch is CancellationError {
            throw CribWireFault.cancelled
        } catch {
            throw CribWireFault.decoding
        }
    }

    private func request(for url: URL) -> URLRequest {
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        return request
    }

    private func fetch(_ request: URLRequest) async throws -> Data {
        do {
            return try await send(request)
        } catch let fault as CribWireFault {
            throw fault
        } catch is CancellationError {
            throw CribWireFault.cancelled
        } catch {
            if Self.cancelled(error) {
                throw CribWireFault.cancelled
            }
            guard Self.transient(error) else { throw CribWireFault.transport }
            do {
                return try await send(request)
            } catch let fault as CribWireFault {
                throw fault
            } catch is CancellationError {
                throw CribWireFault.cancelled
            } catch {
                if Self.cancelled(error) { throw CribWireFault.cancelled }
                throw CribWireFault.transport
            }
        }
    }

    private func send(_ request: URLRequest) async throws -> Data {
        try Task.checkCancellation()
        let (data, response) = try await carrier.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw CribWireFault.invalidResponse
        }
        if http.statusCode == 404 {
            throw CribWireFault.notFound
        }
        guard (200 ..< 300).contains(http.statusCode) else {
            throw CribWireFault.transport
        }
        return data
    }

    private static func transient(_ error: Error) -> Bool {
        guard let urlError = error as? URLError else { return false }
        switch urlError.code {
        case .timedOut, .networkConnectionLost, .notConnectedToInternet,
             .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed:
            return true
        default:
            return false
        }
    }

    private static func cancelled(_ error: Error) -> Bool {
        if error is CancellationError { return true }
        return (error as? URLError)?.code == .cancelled
    }
}
