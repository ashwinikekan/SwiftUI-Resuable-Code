import Testing
import Foundation
@testable import TadaMVL

@MainActor
struct BookDTOMappingTests {

    @Test
    func bookingDTO_usesNicknameWhenSet() {
        let p = LocationPoint(
            id: UUID(),
            latitude: 1, longitude: 2,
            aqi: 30,
            address: "Far Away",
            nickname: "home"
        )

        let dto = p.bookingDTO
        #expect(dto.name == "home")
        #expect(dto.latitude == 1)
        #expect(dto.longitude == 2)
        #expect(dto.aqi == 30)
    }

    @Test
    func bookingDTO_fallsBackToAddressWhenNicknameMissing() {
        let p = LocationPoint(
            id: UUID(),
            latitude: 0, longitude: 0,
            aqi: 0,
            address: "Some Address",
            nickname: nil
        )

        #expect(p.bookingDTO.name == "Some Address")
    }

    @Test
    func locationPoint_fromDTO_putsNameIntoAddress() {
        let dto = BookLocationDTO(latitude: 5, longitude: 6, aqi: 11, name: "Pickup")
        let point = LocationPoint(dto: dto)

        #expect(point.latitude == 5)
        #expect(point.longitude == 6)
        #expect(point.aqi == 11)
        #expect(point.address == "Pickup")
        #expect(point.nickname == nil) // wire doesn't carry it
    }

    @Test
    func book_fromDTO_parsesUUIDWhenProvided() {
        let fixed = UUID()
        let dto = BookResponseDTO(
            id: fixed.uuidString,
            a: BookLocationDTO(latitude: 0, longitude: 0, aqi: 0, name: "A"),
            b: BookLocationDTO(latitude: 1, longitude: 1, aqi: 0, name: "B"),
            price: 10_000
        )

        let book = Book(dto: dto)
        #expect(book.id == fixed)
        #expect(book.a.address == "A")
        #expect(book.b.address == "B")
        #expect(book.price == 10_000)
    }

    @Test
    func book_fromDTO_generatesUUIDWhenServerOmitsId() {
        // If the server returns no id (or a non-UUID string) we still want a
        // valid Book back, so the init falls back to a fresh UUID.
        let dto = BookResponseDTO(
            id: nil,
            a: BookLocationDTO(latitude: 0, longitude: 0, aqi: 0, name: "A"),
            b: BookLocationDTO(latitude: 0, longitude: 0, aqi: 0, name: "B"),
            price: 0
        )

        let book = Book(dto: dto)
        // Don't assert a specific value - just that we got SOMETHING valid.
        #expect(book.id.uuidString.count == 36)
    }

    @Test
    func book_fromDTO_handlesGarbageIdGracefully() {
        let dto = BookResponseDTO(
            id: "not-a-uuid",
            a: BookLocationDTO(latitude: 0, longitude: 0, aqi: 0, name: "A"),
            b: BookLocationDTO(latitude: 0, longitude: 0, aqi: 0, name: "B"),
            price: 0
        )

        let book = Book(dto: dto)
        #expect(book.id.uuidString.count == 36)
    }
}
