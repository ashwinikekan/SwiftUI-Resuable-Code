import Foundation
import CoreLocation

protocol FetchAQIUseCaseProtocol {
    func execute(latitude: Double, longitude: Double) async throws -> Int
    func execute(coordinate: CLLocationCoordinate2D) async throws -> Int
}

struct FetchAQIUseCase: FetchAQIUseCaseProtocol {

    private let repository: AirQualityRepository

    init(repository: AirQualityRepository) {
        self.repository = repository
    }

    func execute(latitude: Double, longitude: Double) async throws -> Int {
        try await repository.fetchAQI(latitude: latitude, longitude: longitude)
    }

    func execute(coordinate: CLLocationCoordinate2D) async throws -> Int {
        try await execute(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}
