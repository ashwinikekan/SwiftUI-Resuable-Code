import Testing
import CoreLocation
@testable import TadaMVL

@MainActor
struct FetchAQIUseCaseTests {

    @Test
    func passesCoordinateToRepositoryAndReturnsValue() async throws {
        let repository = StubAirQualityRepository(result: 80)
        let useCase = FetchAQIUseCase(repository: repository)

        let aqi = try await useCase.execute(
            coordinate: CLLocationCoordinate2D(latitude: 19.06, longitude: 72.83)
        )

        #expect(aqi == 80)
        #expect(repository.lastCall?.lat == 19.06)
        #expect(repository.lastCall?.lon == 72.83)
    }

    @Test
    func propagatesRepositoryErrors() async {
        let repository = StubAirQualityRepository(error: AQITestError.boom)
        let useCase = FetchAQIUseCase(repository: repository)

        await #expect(throws: AQITestError.self) {
            _ = try await useCase.execute(latitude: 0, longitude: 0)
        }
    }
}

private enum AQITestError: Error { case boom }

private final class StubAirQualityRepository: AirQualityRepository {
    var result: Int = 0
    var error: Error?
    var lastCall: (lat: Double, lon: Double)?

    init(result: Int = 0, error: Error? = nil) {
        self.result = result
        self.error = error
    }

    func fetchAQI(latitude: Double, longitude: Double) async throws -> Int {
        lastCall = (latitude, longitude)
        if let error { throw error }
        return result
    }
}
