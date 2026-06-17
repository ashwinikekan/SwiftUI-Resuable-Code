import Foundation
import Alamofire

protocol APIClientProtocol {

    func request<T: Decodable>(
        _ url: String,
        method: HTTPMethod,
        parameters: Parameters?
    ) async throws -> T

    func request<Body: Encodable, T: Decodable>(
        _ url: String,
        method: HTTPMethod,
        body: Body
    ) async throws -> T
}
