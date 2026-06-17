import Testing
import Foundation
@testable import TadaMVL


@MainActor
struct CreateBookUseCaseTests {

    @Test
    func passesABThroughAndReturnsResult() async throws {
        let stub = StubBookingRepository()
        let expected = Book(
            id: UUID(),
            a: makePoint("A"),
            b: makePoint("B"),
            price: 10_000
        )
        stub.createResult = expected

        let uc = CreateBookUseCase(repository: stub)
        let actual = try await uc.execute(a: makePoint("A"), b: makePoint("B"))

        #expect(actual.id == expected.id)
        #expect(stub.createCalls == 1)
    }

    @Test
    func bubblesRepositoryError() async {
        let stub = StubBookingRepository()
        stub.error = FakeError.canned
        let uc = CreateBookUseCase(repository: stub)

        await #expect(throws: FakeError.self) {
            _ = try await uc.execute(a: makePoint("A"), b: makePoint("B"))
        }
    }
}

@MainActor
struct FetchBooksUseCaseTests {

    @Test
    func passesYearMonthThroughAndReturnsList() async throws {
        let stub = StubBookingRepository()
        stub.fetchResult = [
            Book(id: UUID(), a: makePoint("A"), b: makePoint("B"), price: 1),
            Book(id: UUID(), a: makePoint("A"), b: makePoint("B"), price: 2),
        ]

        let uc = FetchBooksUseCase(repository: stub)
        let list = try await uc.execute(year: 2026, month: 5)
        #expect(list.count == 2)
        #expect(stub.lastFetchYM?.year == 2026)
        #expect(stub.lastFetchYM?.month == 5)
    }
}

// MARK: helpers

private func makePoint(_ name: String) -> LocationPoint {
    LocationPoint(
        id: UUID(),
        latitude: 0, longitude: 0,
        aqi: 0,
        address: name,
        nickname: nil
    )
}

private final class StubBookingRepository: BookingRepository {
    var createResult: Book?
    var fetchResult: [Book] = []
    var error: Error?
    var createCalls = 0
    var lastFetchYM: (year: Int, month: Int)?

    func createBook(a: LocationPoint, b: LocationPoint) async throws -> Book {
        createCalls += 1
        if let error { throw error }
        if let createResult { return createResult }
        return Book(id: UUID(), a: a, b: b, price: 0)
    }

    func fetchBooks(year: Int, month: Int) async throws -> [Book] {
        lastFetchYM = (year, month)
        if let error { throw error }
        return fetchResult
    }
}
