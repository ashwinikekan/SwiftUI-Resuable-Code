import Testing
import Foundation
import Alamofire
@testable import TadaMVL

@Suite(.serialized)
struct APIClientImplTests {

    @Test
    func get_decodesJSONFromStubbedResponse() async throws {
        defer { StubURLProtocol.handler = nil }
        StubURLProtocol.handler = { req in
            let response = StubURLProtocol.httpResponse(for: req, statusCode: 200)
            return (response, Data(#"{"status":"ok","data":{"aqi":91}}"#.utf8))
        }
        let client = makeClient()

        let result: AQIResponse = try await client.request(
            "https://example.test/feed",
            method: .get,
            parameters: ["token": "abc"]
        )

        #expect(result.status == "ok")
        #expect(result.data.aqi == 91)
    }

    @Test
    func post_jsonEncodesBody() async throws {
        defer { StubURLProtocol.handler = nil }

        // Captured on the URLProtocol thread — use a lock so the assertion
        // doesn't race with the handler.
        let lock = NSLock()
        var receivedBody: Data?

        StubURLProtocol.handler = { req in
            let body = req.bodyData
            lock.lock()
            receivedBody = body
            lock.unlock()
            let response = StubURLProtocol.httpResponse(for: req, statusCode: 200)
            return (response, Data(#"{"echo":true}"#.utf8))
        }
        let client = makeClient()

        struct Echo: Codable { let echo: Bool }
        let body = BookRequestDTO(
            a: BookLocationDTO(latitude: 1, longitude: 2, aqi: 3, name: "A"),
            b: BookLocationDTO(latitude: 4, longitude: 5, aqi: 6, name: "B")
        )

        let _: Echo = try await client.request(
            "https://example.test/books",
            method: .post,
            body: body
        )

        lock.lock()
        let captured = receivedBody
        lock.unlock()

        let decoded = try JSONDecoder().decode(BookRequestDTO.self, from: captured ?? Data())
        #expect(decoded == body)
    }

    @Test
    func get_throwsWhenServerReturns500() async {
        defer { StubURLProtocol.handler = nil }
        StubURLProtocol.handler = { req in
            let response = StubURLProtocol.httpResponse(for: req, statusCode: 500)
            return (response, Data())
        }
        let client = makeClient()

        await #expect(throws: (any Error).self) {
            let _: AQIResponse = try await client.request(
                "https://example.test/oops",
                method: .get,
                parameters: nil
            )
        }
    }

    @Test
    func post_throwsWhenServerReturnsMalformedJSON() async {
        defer { StubURLProtocol.handler = nil }
        StubURLProtocol.handler = { req in
            let response = StubURLProtocol.httpResponse(for: req, statusCode: 200)
            return (response, Data("not json".utf8))
        }
        let client = makeClient()

        await #expect(throws: (any Error).self) {
            let _: BookResponseDTO = try await client.request(
                "https://example.test/books",
                method: .post,
                body: BookRequestDTO(
                    a: BookLocationDTO(latitude: 0, longitude: 0, aqi: 0, name: "A"),
                    b: BookLocationDTO(latitude: 0, longitude: 0, aqi: 0, name: "B")
                )
            )
        }
    }

    // MARK: helpers

    private func makeClient() -> APIClientImpl {
        // Use plain `default` — `ephemeral` + custom protocolClasses has been
        // flaky on some iOS versions (protocol never invoked → request hangs).
        let config = URLSessionConfiguration.default
        config.protocolClasses = [StubURLProtocol.self]
        config.urlCache = nil
        config.requestCachePolicy = .reloadIgnoringLocalCacheData

        let session = Session(configuration: config)
        return APIClientImpl(session: session)
    }
}

// MARK: URLProtocol stub

final class StubURLProtocol: URLProtocol, @unchecked Sendable {

    nonisolated(unsafe) static var handler: ((URLRequest) -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }

        let (response, data) = handler(request)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    /// Build a response tied to the outgoing request URL — some stacks are
    /// picky about mismatched response.url vs request.url.
    static func httpResponse(for request: URLRequest, statusCode: Int) -> HTTPURLResponse {
        let url = request.url ?? URL(string: "https://example.test")!
        return HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
    }
}

private extension URLRequest {
    /// URLProtocol delivers the body via stream, so reach in and read it.
    var bodyData: Data? {
        if let body = httpBody { return body }
        guard let stream = httpBodyStream else { return nil }
        stream.open()
        defer { stream.close() }
        var buffer = [UInt8](repeating: 0, count: 4096)
        var data = Data()
        while stream.hasBytesAvailable {
            let read = stream.read(&buffer, maxLength: buffer.count)
            if read <= 0 { break }
            data.append(buffer, count: read)
        }
        return data
    }
}
