import Foundation
import Alamofire

final class BookingRepositoryImpl: BookingRepository {

    private let client: APIClientProtocol

    init(client: APIClientProtocol) {
        self.client = client
    }

    func createBook(a: LocationPoint, b: LocationPoint) async throws -> Book {

        let url = "\(APIConstants.bookingBaseURL)/books"
        let body = BookRequestDTO(a: a.bookingDTO, b: b.bookingDTO)

        let response: BookResponseDTO = try await client.request(url, method: .post, body: body)

        // Keep our local A and B as the source of truth rather than rebuilding
        // from the response DTOs. The wire format only carries `name`, so
        // re-hydrating would drop the nickname and stable UUID we already have.
        return Book(
            id: response.id.flatMap(UUID.init(uuidString:)) ?? UUID(),
            a: a,
            b: b,
            price: response.price
        )
    }

    func fetchBooks(year: Int, month: Int) async throws -> [Book] {

        let url = "\(APIConstants.bookingBaseURL)/books"
        let params: [String: Any] = ["year": year, "month": month]

        let response: [BookResponseDTO] = try await client.request(url, method: .get, parameters: params)

        return response.map(Book.init(dto:))
    }
}
