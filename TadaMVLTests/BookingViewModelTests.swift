import Testing
import Foundation
@testable import TadaMVL

@MainActor
struct BookingViewModelTests {

    @Test
    func create_setsBookOnSuccess() async throws {
        let uc = StubCreateBookUseCase()
        let expected = Book(
            id: UUID(),
            a: makePoint("A"),
            b: makePoint("B"),
            price: 10_000
        )
        uc.result = expected

        let sut = BookingViewModel(createBookUseCase: uc)
        sut.send(.create(a: makePoint("A"), b: makePoint("B")))

        try await waitForBookOrError(sut)

        #expect(sut.state.book?.id == expected.id)
        #expect(sut.state.errorMessage == nil)
        #expect(sut.state.isLoading == false)
    }

    @Test
    func create_setsErrorMessageOnFailure() async throws {
        let uc = StubCreateBookUseCase()
        uc.error = FakeError.canned

        let sut = BookingViewModel(createBookUseCase: uc)
        sut.send(.create(a: makePoint("A"), b: makePoint("B")))

        try await waitForBookOrError(sut)

        #expect(sut.state.book == nil)
        #expect(sut.state.errorMessage != nil)
        #expect(sut.state.isLoading == false)
    }

    @Test
    func dismissError_clearsErrorMessage() async throws {
        let uc = StubCreateBookUseCase()
        uc.error = FakeError.canned

        let sut = BookingViewModel(createBookUseCase: uc)
        sut.send(.create(a: makePoint("A"), b: makePoint("B")))
        try await waitForBookOrError(sut)
        #expect(sut.state.errorMessage != nil)

        sut.send(.dismissError)
        #expect(sut.state.errorMessage == nil)
    }

    // MARK: helpers

    // Polls state instead of using XCTestExpectation; Swift Testing doesn't
    // have a "wait until" helper out of the box and the task takes ~zero time
    // with a stub use case.
    private func waitForBookOrError(_ vm: BookingViewModel, timeoutMs: Int = 3_000) async throws {
        let deadline = Date().addingTimeInterval(Double(timeoutMs) / 1000)
        while Date() < deadline {
            if vm.state.book != nil || vm.state.errorMessage != nil {
                return
            }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
    }
}

private func makePoint(_ name: String) -> LocationPoint {
    LocationPoint(
        id: UUID(),
        latitude: 0, longitude: 0,
        aqi: 0, address: name, nickname: nil
    )
}

private final class StubCreateBookUseCase: CreateBookUseCaseProtocol {
    var result: Book?
    var error: Error?

    func execute(a: LocationPoint, b: LocationPoint) async throws -> Book {
        if let error { throw error }
        return result ?? Book(id: UUID(), a: a, b: b, price: 0)
    }
}
