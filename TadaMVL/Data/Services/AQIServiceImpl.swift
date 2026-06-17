import Foundation
import Alamofire
import OSLog

final class AQIServiceImpl: AQIServiceProtocol {

    private let client: APIClientProtocol
    private let log = Logger(subsystem: "com.tada.mvl", category: "aqi")

    init(client: APIClientProtocol) {
        self.client = client
    }

    func fetchAQI(latitude: Double, longitude: Double) async throws -> Int {
        // WAQI exposes feed/geo:<lat>;<lon>/. Token is appended as a query param
        // because their API requires it on every request.
        let url = "\(APIConstants.aqiBaseURL)/feed/geo:\(latitude);\(longitude)/?token=\(APIConstants.aqiToken)"
        log.debug("waqi @ (\(latitude), \(longitude))")

        let response: AQIResponse = try await client.request(url, method: .get, parameters: nil)
        return response.data.aqi
    }
}
