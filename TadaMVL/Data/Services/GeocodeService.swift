import Foundation

protocol GeocodeServiceProtocol {
    func reverseGeocode(latitude: Double, longitude: Double) async throws -> String
}
