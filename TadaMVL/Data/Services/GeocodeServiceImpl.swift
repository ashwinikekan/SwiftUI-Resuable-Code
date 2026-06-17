import Foundation
import Alamofire

final class GeocodeServiceImpl: GeocodeServiceProtocol {

    private let client: APIClientProtocol

    init(client: APIClientProtocol) {
        self.client = client
    }

    func reverseGeocode(latitude: Double, longitude: Double) async throws -> String {

        let url = "\(APIConstants.geocodeBaseURL)/data/reverse-geocode-client"

        let params: Parameters = [
            "latitude": latitude,
            "longitude": longitude,
            "localityLanguage": "en"
        ]

        let response: ReverseGeocodeResponse = try await client.request(
            url,
            method: .get,
            parameters: params
        )

        // The brief asks for the two HIGHEST-order admin entries joined.
        // The sorting + take-2 lives on the response type so it's
        // testable without faking the HTTP layer.
        return response.topTwoAddressNames
    }
}
