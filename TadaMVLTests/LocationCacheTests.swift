import Testing
import Foundation
@testable import TadaMVL


@MainActor
struct LocationCacheTests {

    @Test
    func cacheKey_briefExample1_sameLocation() {
        let a = LocationCache.makeKey(latitude: 37.5642, longitude: 127.0016)
        let b = LocationCache.makeKey(latitude: 37.5645, longitude: 127.0018)
        #expect(a == b)
    }

    @Test
    func cacheKey_briefExample2_differentLocations() {
        let a = LocationCache.makeKey(latitude: 37.5655, longitude: 127.2321)
        let b = LocationCache.makeKey(latitude: 37.5624, longitude: 127.2328)
        #expect(a != b)
    }

    @Test
    func truncatedTo3_dropsFourthDecimal() {
        // The interesting cases are values that would round up under the
        // default rounding mode - confirm we're truncating, not rounding.
        #expect((37.5642).truncatedTo3()  == 37.564)
        #expect((37.5645).truncatedTo3()  == 37.564)
        #expect((37.5655).truncatedTo3()  == 37.565)
        #expect((37.5624).truncatedTo3()  == 37.562)
        #expect((127.0016).truncatedTo3() == 127.001)
        #expect((127.0018).truncatedTo3() == 127.001)
    }

    @Test
    func cache_savesAndFetchesByCoordinate() {
        let cache = LocationCache(userDefaults: Self.makeIsolatedDefaults())
        let point = LocationPoint(
            id: UUID(),
            latitude: 37.5642,
            longitude: 127.0016,
            aqi: 42,
            address: "Seoul, Gangnam-gu",
            nickname: nil
        )

        cache.save(location: point)
        drain(cache)

        // Same bucket - should hit.
        #expect(cache.fetch(latitude: 37.5645, longitude: 127.0018)?.aqi == 42)

        // Different bucket - should miss.
        #expect(cache.fetch(latitude: 37.5655, longitude: 127.2321) == nil)
    }

    @Test
    func cache_savesAddressFromReverseGeocodeLookups() {
        let cache = LocationCache(userDefaults: Self.makeIsolatedDefaults())
        cache.saveAddress(latitude: 37.5642, longitude: 127.0016, address: "Seoul, Gangnam-gu")
        drain(cache)

        #expect(cache.fetchAddress(latitude: 37.5645, longitude: 127.0018) == "Seoul, Gangnam-gu")
        #expect(cache.fetchAddress(latitude: 37.5655, longitude: 127.2321) == nil)
    }

    // MARK: Helpers

    // Fresh UserDefaults suite per test so cached values from one test
    // don't bleed into the next.
    private static func makeIsolatedDefaults() -> UserDefaults {
        let suite = "LocationCacheTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    private func drain(_ cache: LocationCache) {
        _ = cache.allLocations()
    }
}
