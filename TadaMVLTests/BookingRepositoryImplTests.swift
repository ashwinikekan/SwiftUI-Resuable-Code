import Testing
import Foundation
@testable import TadaMVL

@MainActor
struct BookingRepositoryImplTests {

    @Test
    func createBook_postsCorrectBodyAndPreservesLocalAB() async throws {
        let serverID = UUID()
        let serverResponse = BookResponseDTO(
            id: serverID.uuidString,
            a: BookLocationDTO(latitude: 0, longitude: 0, aqi: 0, name: "ignored"),
            b: BookLocationDTO(latitude: 0, longitude: 0, aqi: 0, name: "ignored"),
            price: 10_000
        )

        let client = FakeAPIClient(bodyResponse: serverResponse)
        let sut = BookingRepositoryImpl(client: client)

        let a = makePoint(latitude: 37.5642, longitude: 127.0016, address: "Seoul A", nickname: "home")
        let b = makePoint(latitude: 37.5670, longitude: 127.0000, address: "Seoul B", nickname: nil)

        let book = try await sut.createBook(a: a, b: b)

        // The returned book preserves OUR LocationPoints (id, nickname),
        // not the server-echoed DTOs.
        #expect(book.id == serverID)
        #expect(book.a.id == a.id)
        #expect(book.b.id == b.id)
        #expect(book.a.nickname == "home")
        #expect(book.price == 10_000)

        // Verify the wire body.
        #expect(client.recordedCalls.count == 1)
        guard case .body(let url, let method, let data) = client.recordedCalls.first else {
            Issue.record("expected body call")
            return
        }
        #expect(url == "https://mock.tada.local/books")
        #expect(method == "POST")

        let sentBody = try JSONDecoder().decode(BookRequestDTO.self, from: data ?? Data())
        #expect(sentBody.a.name == "home") // nickname wins
        #expect(sentBody.b.name == "Seoul B") // address fallback
    }

    @Test
    func createBook_propagatesNetworkError() async {
        let client = FakeAPIClient(errorToThrow: FakeError.canned)
        let sut = BookingRepositoryImpl(client: client)

        await #expect(throws: FakeError.self) {
            _ = try await sut.createBook(
                a: makePoint(latitude: 0, longitude: 0, address: "A"),
                b: makePoint(latitude: 0, longitude: 0, address: "B")
            )
        }
    }

    @Test
    func fetchBooks_sendsYearMonthAndMapsResponse() async throws {
        let responses: [BookResponseDTO] = [
            BookResponseDTO(
                id: UUID().uuidString,
                a: BookLocationDTO(latitude: 1, longitude: 1, aqi: 10, name: "A1"),
                b: BookLocationDTO(latitude: 2, longitude: 2, aqi: 20, name: "B1"),
                price: 10_000
            ),
            BookResponseDTO(
                id: UUID().uuidString,
                a: BookLocationDTO(latitude: 3, longitude: 3, aqi: 30, name: "A2"),
                b: BookLocationDTO(latitude: 4, longitude: 4, aqi: 40, name: "B2"),
                price: 12_000
            ),
        ]

        let client = FakeAPIClient(paramResponse: responses)
        let sut = BookingRepositoryImpl(client: client)

        let books = try await sut.fetchBooks(year: 2026, month: 5)
        #expect(books.count == 2)
        #expect(books[0].price == 10_000)
        #expect(books[1].a.address == "A2")

        // Verify the wire params.
        #expect(client.recordedCalls.count == 1)
        guard case .parameters(let url, let method, let params) = client.recordedCalls.first else {
            Issue.record("expected params call")
            return
        }
        #expect(url == "https://mock.tada.local/books")
        #expect(method == "GET")
        #expect(params["year"] == "2026")
        #expect(params["month"] == "5")
    }

    // MARK: helpers

    private func makePoint(
        latitude: Double,
        longitude: Double,
        address: String,
        nickname: String? = nil
    ) -> LocationPoint {
        LocationPoint(
            id: UUID(),
            latitude: latitude,
            longitude: longitude,
            aqi: 0,
            address: address,
            nickname: nickname
        )
    }
}
