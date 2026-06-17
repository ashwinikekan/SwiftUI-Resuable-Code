import Foundation
import CoreLocation

protocol ReverseGeocodeUseCaseProtocol {
    func execute(latitude: Double, longitude: Double) async throws -> String
    func execute(coordinate: CLLocationCoordinate2D) async throws -> String
}

struct ReverseGeocodeUseCase: ReverseGeocodeUseCaseProtocol {

    private let repository: LocationRepository

    init(repository: LocationRepository) {
        self.repository = repository
    }

    func execute(latitude: Double, longitude: Double) async throws -> String {
        try await repository.reverseGeocode(latitude: latitude, longitude: longitude)
    }

    func execute(coordinate: CLLocationCoordinate2D) async throws -> String {
        try await execute(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}
