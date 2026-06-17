import Testing
@testable import TadaMVL

@MainActor
struct AirQualityRepositoryImplTests {

    @Test
    func forwardsCoordinatesAndReturnsValue() async throws {
        let service = FakeAQIService()
        service.result = 73
        let sut = AirQualityRepositoryImpl(service: service)

        let aqi = try await sut.fetchAQI(latitude: 12.34, longitude: 56.78)

        #expect(aqi == 73)
        #expect(service.calls.count == 1)
        #expect(service.calls.first?.lat == 12.34)
        #expect(service.calls.first?.lon == 56.78)
    }

    @Test
    func propagatesServiceErrors() async {
        let service = FakeAQIService()
        service.error = FakeError.canned
        let sut = AirQualityRepositoryImpl(service: service)

        await #expect(throws: FakeError.self) {
            _ = try await sut.fetchAQI(latitude: 0, longitude: 0)
        }
    }
}
