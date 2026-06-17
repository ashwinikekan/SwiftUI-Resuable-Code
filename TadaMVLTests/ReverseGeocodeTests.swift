import Testing
@testable import TadaMVL


@MainActor
struct ReverseGeocodeTests {

    @Test
    func picksTopTwoHighestOrderNames() {
        let response = ReverseGeocodeResponse(
            localityInfo: LocalityInfo(administrative: [
                AdministrativeArea(name: "Earth",             order: 1),
                AdministrativeArea(name: "Asia",              order: 2),
                AdministrativeArea(name: "Republic of Korea", order: 3),
                AdministrativeArea(name: "Seoul",             order: 4),
                AdministrativeArea(name: "Gangnam-gu",        order: 5),
            ])
        )

        #expect(response.topTwoAddressNames == "Gangnam-gu, Seoul")
    }

    @Test
    func handlesUnorderedInputBySortingDescending() {
        let response = ReverseGeocodeResponse(
            localityInfo: LocalityInfo(administrative: [
                AdministrativeArea(name: "Seoul",      order: 4),
                AdministrativeArea(name: "Gangnam-gu", order: 5),
                AdministrativeArea(name: "Earth",      order: 1),
            ])
        )

        #expect(response.topTwoAddressNames == "Gangnam-gu, Seoul")
    }

    @Test
    func handlesSingleAdministrativeLevel() {
        let response = ReverseGeocodeResponse(
            localityInfo: LocalityInfo(administrative: [
                AdministrativeArea(name: "Tokyo", order: 4)
            ])
        )

        #expect(response.topTwoAddressNames == "Tokyo")
    }

    @Test
    func handlesEmptyAdministrative() {
        let response = ReverseGeocodeResponse(
            localityInfo: LocalityInfo(administrative: [])
        )

        #expect(response.topTwoAddressNames == "")
    }

    // The use case is a thin pass-through, but worth pinning so we notice
    // if someone adds caching/transformation there by accident.
    @Test
    func useCase_returnsRepositoryResult() async throws {
        let repository = StubLocationRepository(result: "Mumbai, Bandra West")
        let useCase = ReverseGeocodeUseCase(repository: repository)

        let result = try await useCase.execute(latitude: 19.06, longitude: 72.83)

        #expect(result == "Mumbai, Bandra West")
        #expect(repository.calls == [(19.06, 72.83)])
    }
}

private final class StubLocationRepository: LocationRepository {
    var result: String
    var calls: [(Double, Double)] = []

    init(result: String) { self.result = result }

    func reverseGeocode(latitude: Double, longitude: Double) async throws -> String {
        calls.append((latitude, longitude))
        return result
    }
}

// Tuples aren't Equatable by default - small helper for the calls array.
private func == (lhs: [(Double, Double)], rhs: [(Double, Double)]) -> Bool {
    guard lhs.count == rhs.count else { return false }
    return zip(lhs, rhs).allSatisfy { $0.0 == $1.0 && $0.1 == $1.1 }
}
