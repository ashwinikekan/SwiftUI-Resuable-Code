import Foundation
import Combine

@MainActor
final class BookingViewModel: ObservableObject {

    struct State {
        var book: Book?
        var isLoading: Bool = false
        var errorMessage: String?
    }

    enum Action {
        case create(a: LocationPoint, b: LocationPoint)
        case dismissError
    }

    @Published private(set) var state = State()

    private let createBookUseCase: CreateBookUseCaseProtocol

    init(createBookUseCase: CreateBookUseCaseProtocol) {
        self.createBookUseCase = createBookUseCase
    }

    func send(_ action: Action) {
        switch action {
        case .create(let a, let b):
            Task { await create(a: a, b: b) }
        case .dismissError:
            state.errorMessage = nil
        }
    }

    private func create(a: LocationPoint, b: LocationPoint) async {
        do {
            state.isLoading = true
            state.book = try await createBookUseCase.execute(a: a, b: b)
            state.isLoading = false
        } catch {
            state.isLoading = false
            state.errorMessage = error.localizedDescription
        }
    }
}
