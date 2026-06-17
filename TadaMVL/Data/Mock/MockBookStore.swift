import Foundation

final class MockBookStore {

    private var bookings: [(date: Date, dto: BookResponseDTO)] = []
    private let queue = DispatchQueue(label: "com.tada.mvl.mock-book-store")

    private let pricePicker: () -> Double

    init(pricePicker: @escaping () -> Double = { 10_000 }) {
        self.pricePicker = pricePicker
    }

    @discardableResult
    func insert(request: BookRequestDTO, now: Date = Date()) -> BookResponseDTO {
        queue.sync {
            let response = BookResponseDTO(
                id: UUID().uuidString,
                a: request.a,
                b: request.b,
                price: pricePicker()
            )
            bookings.append((date: now, dto: response))
            return response
        }
    }

    func list(year: Int, month: Int) -> [BookResponseDTO] {
        queue.sync {
            let cal = Calendar.current
            return bookings
                .filter {
                    let c = cal.dateComponents([.year, .month], from: $0.date)
                    return c.year == year && c.month == month
                }
                .map(\.dto)
        }
    }

    // For tests.
    func reset() {
        queue.sync { bookings.removeAll() }
    }
}
