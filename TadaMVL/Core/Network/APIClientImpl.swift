import Foundation
import Alamofire

final class APIClientImpl: APIClientProtocol {

    private let session: Session

    init(session: Session = .default) {
        self.session = session
    }

    func request<T: Decodable>(
        _ url: String,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil
    ) async throws -> T {

        let task = session
            .request(url, method: method, parameters: parameters)
            .validate()
            .serializingDecodable(T.self)

        switch await task.response.result {
        case .success(let value): return value
        case .failure(let error): throw error
        }
    }

    func request<Body: Encodable, T: Decodable>(
        _ url: String,
        method: HTTPMethod,
        body: Body
    ) async throws -> T {

  
        let task = session
            .request(url, method: method, parameters: body, encoder: JSONParameterEncoder.default)
            .validate()
            .serializingDecodable(T.self)

        switch await task.response.result {
        case .success(let value): return value
        case .failure(let error): throw error
        }
    }
}
