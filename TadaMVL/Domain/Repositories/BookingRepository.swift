import Foundation

protocol BookingRepository {
    func createBook(a: LocationPoint, b: LocationPoint) async throws -> Book
    func fetchBooks(year: Int, month: Int) async throws -> [Book]
}
