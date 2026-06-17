import Foundation

protocol FetchBooksUseCaseProtocol {
    func execute(year: Int, month: Int) async throws -> [Book]
}

struct FetchBooksUseCase: FetchBooksUseCaseProtocol {

    private let repository: BookingRepository

    init(repository: BookingRepository) {
        self.repository = repository
    }

    func execute(year: Int, month: Int) async throws -> [Book] {
        try await repository.fetchBooks(year: year, month: month)
    }
}
