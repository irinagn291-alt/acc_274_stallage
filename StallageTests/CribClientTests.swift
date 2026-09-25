import XCTest
@testable import Stallage

private actor ScriptedCarrier: CribCarrying {
    private var results: [Result<(Data, URLResponse), Error>]
    private var requests: [URLRequest] = []

    init(results: [Result<(Data, URLResponse), Error>]) {
        self.results = results
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        guard !results.isEmpty else { throw URLError(.cannotConnectToHost) }
        return try results.removeFirst().get()
    }

    func recordedRequests() -> [URLRequest] {
        requests
    }
}

final class CribClientTests: XCTestCase {
    private let url = URL(string: "https://stallage-crib.pro/probe")!

    func test_setsUserAgentOnEveryRequest() async throws {
        let carrier = ScriptedCarrier(results: [
            .success((Data("{\"ok\":true}".utf8), try http(200))),
        ])
        let client = CribClient(carrier: carrier)
        let dto = try await client.getJSON(CribProbeDTO.self, from: url)
        XCTAssertTrue(dto.ok)
        let request = await carrier.recordedRequests().first
        XCTAssertEqual(request?.value(forHTTPHeaderField: "User-Agent"), CribClient.userAgent)
        XCTAssertEqual(request?.timeoutInterval, 15)
        XCTAssertEqual(CribClient.userAgent, "Stallage/1.0 (iOS; +https://stallage-crib.pro)")
        XCTAssertEqual(CribClient.contactURL.absoluteString, "https://stallage-crib.pro/contact-us")
        XCTAssertFalse(CribClient.userAgent.contains("OpenFoodFacts"))
        XCTAssertFalse(CribClient.contactURL.absoluteString.contains("search.pl"))
    }

    func test_retriesTransientTransportOnce() async throws {
        let carrier = ScriptedCarrier(results: [
            .failure(URLError(.timedOut)),
            .success((Data("{\"ok\":true}".utf8), try http(200))),
        ])
        let client = CribClient(carrier: carrier)
        let dto = try await client.getJSON(CribProbeDTO.self, from: url)
        XCTAssertTrue(dto.ok)
        let count = await carrier.recordedRequests().count
        XCTAssertEqual(count, 2)
    }

    func test_doesNotRetry404() async throws {
        let carrier = ScriptedCarrier(results: [
            .success((Data(), try http(404))),
            .success((Data("{\"ok\":true}".utf8), try http(200))),
        ])
        let client = CribClient(carrier: carrier)
        do {
            _ = try await client.getJSON(CribProbeDTO.self, from: url)
            XCTFail("expected notFound")
        } catch {
            XCTAssertEqual(error as? CribWireFault, .notFound)
        }
        let count = await carrier.recordedRequests().count
        XCTAssertEqual(count, 1)
    }

    func test_secondTransientFailureIsTransport() async {
        let carrier = ScriptedCarrier(results: [
            .failure(URLError(.cannotConnectToHost)),
            .failure(URLError(.timedOut)),
        ])
        let client = CribClient(carrier: carrier)
        do {
            _ = try await client.getJSON(CribProbeDTO.self, from: url)
            XCTFail("expected transport")
        } catch {
            XCTAssertEqual(error as? CribWireFault, .transport)
        }
        let count = await carrier.recordedRequests().count
        XCTAssertEqual(count, 2)
    }

    func test_cancellationIsNotRetried() async throws {
        let carrier = ScriptedCarrier(results: [
            .failure(CancellationError()),
            .success((Data("{\"ok\":true}".utf8), try http(200))),
        ])
        let client = CribClient(carrier: carrier)
        do {
            _ = try await client.getJSON(CribProbeDTO.self, from: url)
            XCTFail("expected cancelled")
        } catch {
            XCTAssertEqual(error as? CribWireFault, .cancelled)
        }
        let count = await carrier.recordedRequests().count
        XCTAssertEqual(count, 1)
    }

    func test_malformedJSONIsDecodingError() async throws {
        let carrier = ScriptedCarrier(results: [
            .success((Data("{".utf8), try http(200))),
        ])
        let client = CribClient(carrier: carrier)
        do {
            _ = try await client.getJSON(CribProbeDTO.self, from: url)
            XCTFail("expected decoding")
        } catch {
            XCTAssertEqual(error as? CribWireFault, .decoding)
        }
    }

    private func http(_ status: Int) throws -> HTTPURLResponse {
        try XCTUnwrap(HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil))
    }
}
