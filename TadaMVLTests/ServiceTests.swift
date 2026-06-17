import Testing
@testable import TadaMVL

@MainActor
struct AQIServiceImplTests {

    @Test
    func buildsWAQIUrlAndReturnsAQI() async throws {
        let canned = AQIResponse(status: "ok", data: AQIData(aqi: 65))
        let client = FakeAPIClient(paramResponse: canned)
        let sut = AQIServiceImpl(client: client)

        let aqi = try await sut.fetchAQI(latitude: 37.5665, longitude: 126.978)

        #expect(aqi == 65)
        #expect(client.recordedCalls.count == 1)
        guard case .parameters(let url, let method, _) = client.recordedCalls[0] else {
            Issue.record("expected parameters call")
            return
        }

        #expect(method == "GET")
        #expect(url.hasPrefix("\(APIConstants.aqiBaseURL)/feed/geo:37.5665;126.978/"))
        #expect(url.contains("token=\(APIConstants.aqiToken)"))
    }

    @Test
    func propagatesClientError() async {
        let client = FakeAPIClient(errorToThrow: FakeError.canned)
        let sut = AQIServiceImpl(client: client)

        await #expect(throws: FakeError.self) {
            _ = try await sut.fetchAQI(latitude: 0, longitude: 0)
        }
    }
}

@MainActor
struct GeocodeServiceImplTests {

    @Test
    func sendsExpectedParametersAndExtractsTopTwoNames() async throws {
        let canned = ReverseGeocodeResponse(
            localityInfo: LocalityInfo(administrative: [
                AdministrativeArea(name: "Earth", order: 1),
                AdministrativeArea(name: "Republic of Korea", order: 3),
                AdministrativeArea(name: "Seoul", order: 4),
                AdministrativeArea(name: "Gangnam-gu", order: 5),
            ])
        )
        let client = FakeAPIClient(paramResponse: canned)
        let sut = GeocodeServiceImpl(client: client)

        let address = try await sut.reverseGeocode(latitude: 37.5665, longitude: 126.978)
        #expect(address == "Gangnam-gu, Seoul")

        guard case .parameters(let url, let method, let params) = client.recordedCalls.first else {
            Issue.record("expected parameters call")
            return
        }
        #expect(method == "GET")
        #expect(url == "\(APIConstants.geocodeBaseURL)/data/reverse-geocode-client")
        #expect(params["latitude"] == "37.5665")
        #expect(params["longitude"] == "126.978")
        #expect(params["localityLanguage"] == "en")
    }
}
