import Foundation
import OSLog

final class LocationRepositoryImpl: LocationRepository {

    private let service: GeocodeServiceProtocol
    private let cache: LocationCaching
    private let log = Logger(subsystem: "com.tada.mvl", category: "geocode")

    init(service: GeocodeServiceProtocol, cache: LocationCaching) {
        self.service = service
        self.cache = cache
    }

    func reverseGeocode(latitude: Double, longitude: Double) async throws -> String {
        // Cache is keyed by 3-decimal truncation, so a hit at one nearby
        // coordinate serves all coordinates that round to the same bucket.
        if let cached = cache.fetchAddress(latitude: latitude, longitude: longitude) {
            log.debug("cache hit (\(latitude), \(longitude))")
            return cached
        }

        let address = try await service.reverseGeocode(latitude: latitude, longitude: longitude)
        cache.saveAddress(latitude: latitude, longitude: longitude, address: address)
        return address
    }
}
