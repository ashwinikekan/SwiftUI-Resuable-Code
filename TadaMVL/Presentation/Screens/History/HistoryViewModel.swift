import Foundation
import Combine

@MainActor
final class HistoryViewModel: ObservableObject {

    struct State {
        var books: [Book] = []
        var isLoading: Bool = false
        var errorMessage: String?

        var totalRecords: Int { books.count }
        var totalPrice: Double { books.reduce(0) { $0 + $1.price } }
    }

    enum Action {
        case load
        case dismissError
    }

    @Published private(set) var state = State()

    private let fetchBooksUseCase: FetchBooksUseCaseProtocol

    init(fetchBooksUseCase: FetchBooksUseCaseProtocol) {
        self.fetchBooksUseCase = fetchBooksUseCase
    }

    func send(_ action: Action) {
        switch action {
        case .load:
            Task { await load() }
        case .dismissError:
            state.errorMessage = nil
        }
    }

    private func load() async {
        do {
            state.isLoading = true
            // Always load the current month - matches the brief's example.
            let cal = Calendar.current
            let now = Date()
            state.books = try await fetchBooksUseCase.execute(
                year: cal.component(.year, from: now),
                month: cal.component(.month, from: now)
            )
            state.isLoading = false
        } catch {
            state.isLoading = false
            state.errorMessage = error.localizedDescription
        }
    }
}
