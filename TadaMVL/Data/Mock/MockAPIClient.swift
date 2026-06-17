import Foundation
import Alamofire
import OSLog

final class MockAPIClient: APIClientProtocol {

    private let passthrough: APIClientProtocol
    private let store: MockBookStore
    private let log = Logger(subsystem: "com.tada.mvl", category: "mock-api")

    init(passthrough: APIClientProtocol, store: MockBookStore = MockBookStore()) {
        self.passthrough = passthrough
        self.store = store
    }

    func request<T: Decodable>(
        _ url: String,
        method: HTTPMethod,
        parameters: Parameters?
    ) async throws -> T {

        guard url.contains("/books") else {
            return try await passthrough.request(url, method: method, parameters: parameters)
        }

        guard method == .get else {
            throw MockAPIError.unsupportedMethod(method.rawValue)
        }

        let year = intParam(parameters, "year") ?? Calendar.current.component(.year, from: Date())
        let month = intParam(parameters, "month") ?? Calendar.current.component(.month, from: Date())

        let result = store.list(year: year, month: month)
        log.debug("Mock GET /books?year=\(year)&month=\(month) -> \(result.count) items")
        return try roundTrip(result)
    }

    // POST /books (other body methods pass through)
    func request<Body: Encodable, T: Decodable>(
        _ url: String,
        method: HTTPMethod,
        body: Body
    ) async throws -> T {

        guard url.contains("/books") else {
            return try await passthrough.request(url, method: method, body: body)
        }

        guard method == .post else {
            throw MockAPIError.unsupportedMethod(method.rawValue)
        }

        // Re-decode the body into the DTO we know how to handle. This way
        // any caller whose Body matches the BookRequestDTO shape works.
        let bodyData = try JSONEncoder().encode(body)
        let request = try JSONDecoder().decode(BookRequestDTO.self, from: bodyData)
        let response = store.insert(request: request)
        log.debug("Mock POST /books -> id=\(response.id ?? "nil") price=\(response.price)")
        return try roundTrip(response)
    }

    private func roundTrip<T: Decodable, Source: Encodable>(_ source: Source) throws -> T {
        let data = try JSONEncoder().encode(source)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func intParam(_ params: Parameters?, _ key: String) -> Int? {
        if let v = params?[key] as? Int { return v }
        if let s = params?[key] as? String, let v = Int(s) { return v }
        return nil
    }
}

enum MockAPIError: LocalizedError {
    case unsupportedMethod(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedMethod(let raw):
            return "MockAPIClient: \(raw) is not supported on /books"
        }
    }
}
