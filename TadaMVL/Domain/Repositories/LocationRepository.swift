import Foundation

protocol LocationRepository {
    func reverseGeocode(latitude: Double, longitude: Double) async throws -> String
}
