import Testing
import Foundation
@testable import TadaMVL

@MainActor
struct LocationPointTests {

    @Test
    func displayName_prefersNicknameWhenSet() {
        let p = makePoint(nickname: "home")
        #expect(p.displayName == "home")
    }

    @Test
    func displayName_fallsBackToAddressWhenNicknameNil() {
        let p = makePoint(nickname: nil)
        #expect(p.displayName == "Seoul, Gangnam-gu")
    }

    @Test
    func displayName_fallsBackToAddressWhenNicknameEmpty() {
        // Empty string is a real case - user can clear the TextField on the
        // detail screen, leaving "" rather than nil.
        let p = makePoint(nickname: "")
        #expect(p.displayName == "Seoul, Gangnam-gu")
    }

    @Test
    func equality_byAllFields() {
        let a = makePoint(nickname: "home")
        let b = makePoint(id: a.id, nickname: "home")
        #expect(a == b)
    }

    @Test
    func equality_differsWhenNicknameChanges() {
        let a = makePoint(nickname: nil)
        let b = makePoint(id: a.id, nickname: "home")
        #expect(a != b)
    }

    // MARK: helpers

    private func makePoint(
        id: UUID = UUID(),
        nickname: String?
    ) -> LocationPoint {
        LocationPoint(
            id: id,
            latitude: 37.5642,
            longitude: 127.0016,
            aqi: 42,
            address: "Seoul, Gangnam-gu",
            nickname: nickname
        )
    }
}
