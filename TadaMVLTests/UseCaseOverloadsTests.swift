import Testing
import CoreLocation
@testable import TadaMVL



@MainActor
struct UseCaseOverloadsTests {

    @Test
    func reverseGeocode_coordinateOverloadCallsLatLon() async throws {
        let repo = StubLocationRepo()
        repo.result = "Mumbai, Bandra"
        let uc = ReverseGeocodeUseCase(repository: repo)

        let result = try await uc.execute(
            coordinate: CLLocationCoordinate2D(latitude: 19.06, longitude: 72.83)
        )
        #expect(result == "Mumbai, Bandra")
        #expect(repo.calls.first?.lat == 19.06)
    }

    @Test
    func fetchAQI_latLonOverloadGetsThroughToRepository() async throws {
        let repo = StubAQIRepo()
        repo.result = 33
        let uc = FetchAQIUseCase(repository: repo)
        let aqi = try await uc.execute(latitude: 1.0, longitude: 2.0)
        #expect(aqi == 33)
        #expect(repo.lastCall?.lat == 1.0)
    }
}

private final class StubLocationRepo: LocationRepository {
    var result = ""
    var calls: [(lat: Double, lon: Double)] = []
    func reverseGeocode(latitude: Double, longitude: Double) async throws -> String {
        calls.append((latitude, longitude))
        return result
    }
}

private final class StubAQIRepo: AirQualityRepository {
    var result = 0
    var lastCall: (lat: Double, lon: Double)?
    func fetchAQI(latitude: Double, longitude: Double) async throws -> Int {
        lastCall = (latitude, longitude)
        return result
    }
}
