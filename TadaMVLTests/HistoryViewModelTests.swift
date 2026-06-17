import Testing
import Foundation
@testable import TadaMVL

@MainActor
struct HistoryViewModelTests {

    @Test
    func load_populatesBooksAndComputesTotals() async throws {
        let uc = StubFetchBooksUseCase()
        uc.result = [
            Book(id: UUID(), a: makePoint("A1"), b: makePoint("B1"), price: 10_000),
            Book(id: UUID(), a: makePoint("A2"), b: makePoint("B2"), price: 12_500),
            Book(id: UUID(), a: makePoint("A3"), b: makePoint("B3"), price: 7_500),
        ]

        let sut = HistoryViewModel(fetchBooksUseCase: uc)
        sut.send(.load)
        try await wait(until: { sut.state.books.count == 3 || sut.state.errorMessage != nil })

        #expect(sut.state.books.count == 3)
        #expect(sut.state.totalRecords == 3)
        #expect(sut.state.totalPrice == 30_000)
        #expect(sut.state.errorMessage == nil)
        #expect(sut.state.isLoading == false)
    }

    @Test
    func load_setsErrorMessageOnFailure() async throws {
        let uc = StubFetchBooksUseCase()
        uc.error = FakeError.canned

        let sut = HistoryViewModel(fetchBooksUseCase: uc)
        sut.send(.load)
        try await waitForLoadError(sut)

        #expect(sut.state.books.isEmpty)
        #expect(sut.state.errorMessage != nil)
    }

    @Test
    func dismissError_clearsErrorMessage() async throws {
        let uc = StubFetchBooksUseCase()
        uc.error = FakeError.canned
        let sut = HistoryViewModel(fetchBooksUseCase: uc)
        sut.send(.load)
        try await waitForLoadError(sut)

        sut.send(.dismissError)
        #expect(sut.state.errorMessage == nil)
    }

    @Test
    func load_passesCurrentYearAndMonthToUseCase() async throws {
        let uc = StubFetchBooksUseCase()
        let sut = HistoryViewModel(fetchBooksUseCase: uc)
        sut.send(.load)
        // The empty-result happy path: wait until the use case got called.
        try await wait(until: { uc.lastYM != nil })

        let cal = Calendar.current
        let now = Date()
        #expect(uc.lastYM?.year == cal.component(.year, from: now))
        #expect(uc.lastYM?.month == cal.component(.month, from: now))
    }

    // MARK: helpers

    // Generic poll-until. Don't key off `isLoading == false` because that's
    // also the initial value before the Task has started.
    private func wait(
        until predicate: @escaping () -> Bool,
        timeoutMs: Int = 3_000
    ) async throws {
        let deadline = Date().addingTimeInterval(Double(timeoutMs) / 1000)
        while Date() < deadline {
            if predicate() { return }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
    }

    private func waitForLoadError(_ vm: HistoryViewModel, timeoutMs: Int = 3_000) async throws {
        try await wait(until: { vm.state.errorMessage != nil }, timeoutMs: timeoutMs)
    }
}

private func makePoint(_ name: String) -> LocationPoint {
    LocationPoint(
        id: UUID(),
        latitude: 0, longitude: 0,
        aqi: 0, address: name, nickname: nil
    )
}

private final class StubFetchBooksUseCase: FetchBooksUseCaseProtocol {
    var result: [Book] = []
    var error: Error?
    var lastYM: (year: Int, month: Int)?

    func execute(year: Int, month: Int) async throws -> [Book] {
        lastYM = (year, month)
        if let error { throw error }
        return result
    }
}
