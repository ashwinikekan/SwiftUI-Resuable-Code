import Foundation

final class AirQualityRepositoryImpl: AirQualityRepository {

    private let service: AQIServiceProtocol

    init(service: AQIServiceProtocol) {
        self.service = service
    }

    func fetchAQI(latitude: Double, longitude: Double) async throws -> Int {
        try await service.fetchAQI(latitude: latitude, longitude: longitude)
    }
}
