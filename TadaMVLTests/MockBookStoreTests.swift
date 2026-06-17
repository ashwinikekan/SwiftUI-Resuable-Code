import Testing
import Foundation
@testable import TadaMVL


@MainActor
struct MockBookStoreTests {

    @Test
    func insertEchoesABAndAssignsPriceAndId() {
        let store = MockBookStore(pricePicker: { 10_000 })

        let request = BookRequestDTO(
            a: BookLocationDTO(latitude: 36.564, longitude: 127.001, aqi: 30, name: "Seoul A"),
            b: BookLocationDTO(latitude: 36.567, longitude: 127.0,   aqi: 40, name: "Seoul B")
        )

        let response = store.insert(request: request)

        #expect(response.a == request.a)
        #expect(response.b == request.b)
        #expect(response.price == 10_000)
        #expect(response.id != nil)
    }

    @Test
    func listFiltersByYearAndMonth() {
        let store = MockBookStore(pricePicker: { 10_000 })

        // Three inserts spread across two months. We expect the month
        // filter to pick exactly those two rows.
        let cal = Calendar(identifier: .gregorian)
        let oct2020  = cal.date(from: DateComponents(year: 2020, month: 10, day: 5))!
        let nov2020a = cal.date(from: DateComponents(year: 2020, month: 11, day: 7))!
        let nov2020b = cal.date(from: DateComponents(year: 2020, month: 11, day: 21))!

        let req = BookRequestDTO(
            a: BookLocationDTO(latitude: 0, longitude: 0, aqi: 0, name: "A"),
            b: BookLocationDTO(latitude: 0, longitude: 0, aqi: 0, name: "B")
        )

        _ = store.insert(request: req, now: oct2020)
        _ = store.insert(request: req, now: nov2020a)
        _ = store.insert(request: req, now: nov2020b)

        #expect(store.list(year: 2020, month: 11).count == 2)
        #expect(store.list(year: 2020, month: 10).count == 1)
        #expect(store.list(year: 2021, month: 11).count == 0)
    }

    @Test
    func resetClearsAll() {
        let store = MockBookStore()
        _ = store.insert(request: BookRequestDTO(
            a: BookLocationDTO(latitude: 0, longitude: 0, aqi: 0, name: "A"),
            b: BookLocationDTO(latitude: 0, longitude: 0, aqi: 0, name: "B")
        ))

        store.reset()

        let cal = Calendar.current
        let now = Date()
        let listed = store.list(
            year: cal.component(.year, from: now),
            month: cal.component(.month, from: now)
        )
        #expect(listed.isEmpty)
    }
}
