import Testing
@testable import TadaMVL

@MainActor
struct LocationRepositoryImplTests {

    @Test
    func cacheHit_doesNotCallService() async throws {
        let cache = FakeLocationCache()
        cache.preload(address: "Cached, Seoul", lat: 37.5642, lon: 127.0016)

        let geocode = FakeGeocodeService()
        geocode.result = "SHOULD NOT BE RETURNED"

        let sut = LocationRepositoryImpl(service: geocode, cache: cache)

        let result = try await sut.reverseGeocode(latitude: 37.5645, longitude: 127.0018)

        #expect(result == "Cached, Seoul")
        #expect(geocode.calls.isEmpty)
        #expect(cache.saveAddressCount == 0) // didn't re-save what we already have
    }

    @Test
    func cacheMiss_callsServiceAndStoresResult() async throws {
        let cache = FakeLocationCache()
        let geocode = FakeGeocodeService()
        geocode.result = "Mumbai, Bandra West"

        let sut = LocationRepositoryImpl(service: geocode, cache: cache)
        let result = try await sut.reverseGeocode(latitude: 19.06, longitude: 72.83)

        #expect(result == "Mumbai, Bandra West")
        #expect(geocode.calls.count == 1)
        #expect(geocode.calls.first?.lat == 19.06)
        #expect(cache.saveAddressCount == 1)
        #expect(cache.fetchAddress(latitude: 19.06, longitude: 72.83) == "Mumbai, Bandra West")
    }

    @Test
    func serviceError_propagates_andDoesNotPoisonTheCache() async {
        let cache = FakeLocationCache()
        let geocode = FakeGeocodeService()
        geocode.error = FakeError.canned

        let sut = LocationRepositoryImpl(service: geocode, cache: cache)

        await #expect(throws: FakeError.self) {
            _ = try await sut.reverseGeocode(latitude: 0, longitude: 0)
        }

        // Important: an error shouldn't write anything into the cache.
        #expect(cache.saveAddressCount == 0)
        #expect(cache.fetchAddress(latitude: 0, longitude: 0) == nil)
    }
}
