import Testing
import Foundation
import Alamofire
@testable import TadaMVL

@MainActor
struct MockAPIClientTests {

    // MARK: /books interception

    @Test
    func postBooks_writesToStoreAndReturnsRoundTrippedResponse() async throws {
        let store = MockBookStore(pricePicker: { 10_000 })
        let passthrough = FakeAPIClient()
        let sut = MockAPIClient(passthrough: passthrough, store: store)

        let request = BookRequestDTO(
            a: BookLocationDTO(latitude: 1, longitude: 2, aqi: 30, name: "A"),
            b: BookLocationDTO(latitude: 3, longitude: 4, aqi: 40, name: "B")
        )

        let response: BookResponseDTO = try await sut.request(
            "https://anything/books",
            method: .post,
            body: request
        )

        #expect(response.price == 10_000)
        #expect(response.a == request.a)
        #expect(response.b == request.b)
        // Passthrough should NOT have been called at all.
        #expect(passthrough.recordedCalls.isEmpty)
    }

    @Test
    func getBooks_pullsFromStoreFilteredByYearMonth() async throws {
        let store = MockBookStore(pricePicker: { 10_000 })

        // Plant a record in the current month so the default filter picks it
        // up regardless of when the test runs.
        let request = BookRequestDTO(
            a: BookLocationDTO(latitude: 0, longitude: 0, aqi: 0, name: "A"),
            b: BookLocationDTO(latitude: 0, longitude: 0, aqi: 0, name: "B")
        )
        _ = store.insert(request: request)

        let passthrough = FakeAPIClient()
        let sut = MockAPIClient(passthrough: passthrough, store: store)

        let cal = Calendar.current
        let now = Date()
        let result: [BookResponseDTO] = try await sut.request(
            "https://anything/books",
            method: .get,
            parameters: [
                "year": cal.component(.year, from: now),
                "month": cal.component(.month, from: now)
            ]
        )

        #expect(result.count == 1)
        #expect(passthrough.recordedCalls.isEmpty)
    }

    @Test
    func getBooks_acceptsStringYearMonthParams() async throws {
        // Some callers stringify their query params. We try-Int both ways.
        let store = MockBookStore()
        let passthrough = FakeAPIClient()
        let sut = MockAPIClient(passthrough: passthrough, store: store)

        let cal = Calendar.current
        let now = Date()
        let yearStr = "\(cal.component(.year, from: now))"
        let monthStr = "\(cal.component(.month, from: now))"

        let result: [BookResponseDTO] = try await sut.request(
            "https://x/books",
            method: .get,
            parameters: ["year": yearStr, "month": monthStr]
        )

        #expect(result.isEmpty)
    }

    @Test
    func getBooks_defaultsToCurrentMonthWhenParamsMissing() async throws {
        // Empty params -> falls back to current year/month.
        let store = MockBookStore()
        _ = store.insert(request: BookRequestDTO(
            a: BookLocationDTO(latitude: 0, longitude: 0, aqi: 0, name: "A"),
            b: BookLocationDTO(latitude: 0, longitude: 0, aqi: 0, name: "B")
        ))

        let sut = MockAPIClient(passthrough: FakeAPIClient(), store: store)
        let result: [BookResponseDTO] = try await sut.request(
            "https://x/books", method: .get, parameters: nil
        )

        #expect(result.count == 1)
    }

    @Test
    func booksWithWrongMethod_throwsUnsupportedMethod() async {
        let sut = MockAPIClient(passthrough: FakeAPIClient())

        // PUT against a body endpoint
        await #expect(throws: MockAPIError.self) {
            let _: BookResponseDTO = try await sut.request(
                "https://x/books",
                method: .put,
                body: BookRequestDTO(
                    a: BookLocationDTO(latitude: 0, longitude: 0, aqi: 0, name: "A"),
                    b: BookLocationDTO(latitude: 0, longitude: 0, aqi: 0, name: "B")
                )
            )
        }

        // DELETE against the parameters endpoint
        await #expect(throws: MockAPIError.self) {
            let _: [BookResponseDTO] = try await sut.request(
                "https://x/books",
                method: .delete,
                parameters: nil
            )
        }
    }

    // MARK: passthrough

    @Test
    func nonBooksGet_forwardsToPassthrough() async throws {
        let response = AQIResponse(status: "ok", data: AQIData(aqi: 88))
        let passthrough = FakeAPIClient(paramResponse: response)
        let sut = MockAPIClient(passthrough: passthrough)

        let actual: AQIResponse = try await sut.request(
            "https://api.waqi.info/feed/geo:0;0/?token=x",
            method: .get,
            parameters: ["q": "value"]
        )

        #expect(actual.data.aqi == 88)
        #expect(passthrough.recordedCalls.count == 1)
    }

    @Test
    func nonBooksPost_forwardsToPassthrough() async throws {
        // Round-trip an arbitrary body type. The mock should never look at it.
        struct PingBody: Encodable, Decodable, Equatable { let hello: String }
        let response = PingBody(hello: "world")
        let passthrough = FakeAPIClient(bodyResponse: response)
        let sut = MockAPIClient(passthrough: passthrough)

        let actual: PingBody = try await sut.request(
            "https://other.example/v1/ping",
            method: .post,
            body: PingBody(hello: "world")
        )

        #expect(actual == response)
        #expect(passthrough.recordedCalls.count == 1)
    }

    // MARK: error description

    @Test
    func mockAPIError_descriptionMentionsMethod() {
        let err = MockAPIError.unsupportedMethod("PUT")
        #expect(err.errorDescription?.contains("PUT") == true)
    }
}
