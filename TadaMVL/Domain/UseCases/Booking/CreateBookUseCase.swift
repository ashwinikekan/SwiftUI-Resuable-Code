import Foundation

protocol CreateBookUseCaseProtocol {
    func execute(a: LocationPoint, b: LocationPoint) async throws -> Book
}

struct CreateBookUseCase: CreateBookUseCaseProtocol {

    private let repository: BookingRepository

    init(repository: BookingRepository) {
        self.repository = repository
    }

    func execute(a: LocationPoint, b: LocationPoint) async throws -> Book {
        try await repository.createBook(a: a, b: b)
    }
}
