import Foundation

protocol AirQualityRepository {
    func fetchAQI(latitude: Double, longitude: Double) async throws -> Int
}
