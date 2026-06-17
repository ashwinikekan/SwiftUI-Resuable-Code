import Testing
import Foundation
import CoreLocation
import MapKit
import SwiftUI
@testable import TadaMVL

@Suite(.serialized)
@MainActor
struct MapViewModelTests {

    // MARK: bookingStep transitions

    @Test
    func initialState_buttonTitleIsSetA() {
        let sut = makeSUT().vm
        #expect(sut.state.bookingStep.buttonTitle == "Set A")
    }

    @Test
    func afterAssignA_buttonTitleIsSetB() {
        let sut = makeSUT().vm
        let a = Self.makeSeoulA()
        sut.send(.assignA(a))
        #expect(sut.state.bookingStep.buttonTitle == "Set B")
        #expect(sut.state.locationA?.id == a.id)
    }

    @Test
    func afterAssignAAndB_buttonTitleIsBook() {
        let sut = makeSUT().vm
        sut.send(.assignA(Self.makeSeoulA()))
        sut.send(.assignB(Self.makeSeoulB()))
        #expect(sut.state.bookingStep.buttonTitle == "Book")
    }

    // MARK: updateLocation

    @Test
    func updateLocation_replacesMatchingSlot() {
        let sut = makeSUT().vm
        let a = Self.makeSeoulA()
        sut.send(.assignA(a))

        var renamed = a
        renamed.nickname = "home"
        sut.send(.updateLocation(renamed))

        #expect(sut.state.locationA?.nickname == "home")
        // B was never set, so it should remain nil.
        #expect(sut.state.locationB == nil)
    }

    // MARK: restore / reset

    @Test
    func restoreBook_prefillsBothSlotsAndKeepsBookStep() async throws {
        let bundle = makeSUT(aqiResult: 99)
        let sut = bundle.vm

        let a = Self.makeSeoulA()
        let b = Self.makeSeoulB()
        let book = Book(id: UUID(), a: a, b: b, price: 10_000)
        sut.send(.restore(book))

        #expect(sut.state.locationA?.id == a.id)
        #expect(sut.state.locationB?.id == b.id)
        #expect(sut.state.bookingStep.buttonTitle == "Book")

        // Region should now be centered on A.
        #expect(abs(sut.state.region.center.latitude - a.latitude)  < 0.0001)
        #expect(abs(sut.state.region.center.longitude - a.longitude) < 0.0001)

        try await Task.sleep(nanoseconds: Self.debouncePadNs)
        #expect(sut.state.currentAQI == 99)
        #expect(bundle.aqi.callCount >= 1)
    }

    @Test
    func reset_clearsSlotsAndOptionallyRecenters() async throws {
        let bundle = makeSUT(aqiResult: 50)
        let sut = bundle.vm
        sut.send(.assignA(Self.makeSeoulA()))
        sut.send(.assignB(Self.makeSeoulB()))

        let recenter = CLLocationCoordinate2D(latitude: 19.06, longitude: 72.83)
        sut.send(.reset(recenterTo: recenter))

        #expect(sut.state.locationA == nil)
        #expect(sut.state.locationB == nil)
        #expect(sut.state.bookingStep.buttonTitle == "Set A")
        #expect(abs(sut.state.region.center.latitude - recenter.latitude) < 0.0001)

        try await Task.sleep(nanoseconds: Self.debouncePadNs)
        #expect(bundle.aqi.callCount >= 1)
    }

    @Test
    func reset_withoutRecenter_keepsCurrentRegionAndDoesNotFetch() async throws {
        let bundle = makeSUT(aqiResult: 0)
        let sut = bundle.vm
        sut.send(.assignA(Self.makeSeoulA()))
        let regionBefore = sut.state.region

        sut.send(.reset(recenterTo: nil))

        #expect(sut.state.locationA == nil)
        #expect(Self.coordEqual(sut.state.region.center, regionBefore.center))

        // Debounce shouldn't fire — wait past debounce window to be sure nothing sneaks in.
        try await Task.sleep(nanoseconds: Self.debouncePadNs)
        #expect(bundle.aqi.callCount == 0)
    }

    // MARK: map interactions

    @Test
    func centerOnUser_movesRegionAndSchedulesAQIFetch() async throws {
        let bundle = makeSUT(aqiResult: 42)
        let sut = bundle.vm

        let coord = CLLocationCoordinate2D(latitude: 19.06, longitude: 72.83)
        sut.send(.centerOnUser(coord))

        #expect(abs(sut.state.region.center.latitude - 19.06) < 0.0001)

        try await Task.sleep(nanoseconds: Self.debouncePadNs)
        #expect(sut.state.currentAQI == 42)
        #expect(bundle.aqi.callCount >= 1)
    }

    @Test
    func mapPanned_triggersAQIFetchButDoesNotMoveRegion() async throws {
        // mapPanned doesn't write to state.region (the binding does that);
        // it just schedules a refetch.
        let bundle = makeSUT(aqiResult: 17)
        let sut = bundle.vm
        let regionBefore = sut.state.region

        let coord = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        sut.send(.mapPanned(coord))

        #expect(sut.state.region.center.latitude == regionBefore.center.latitude)
        try await Task.sleep(nanoseconds: Self.debouncePadNs)
        #expect(sut.state.currentAQI == 17)
    }

    @Test
    func regionBindingWrite_updatesStateRegion() {
        let sut = makeSUT().vm
        let newRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 1, longitude: 2),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
        sut.regionBinding.wrappedValue = newRegion
        #expect(sut.state.region.center.latitude == 1)
        #expect(sut.state.region.center.longitude == 2)
    }

    @Test
    func rapidPans_onlyApplyTheLastResult() async throws {
        // Burst of pans: only the last debounced fetch should win.
        let bundle = makeSUT(aqiResult: 100)
        let sut = bundle.vm

        for i in 0..<5 {
            sut.send(.mapPanned(
                CLLocationCoordinate2D(latitude: Double(i), longitude: 0)
            ))
        }
        try await Task.sleep(nanoseconds: Self.debouncePadNs)

        #expect(bundle.aqi.callCount < 5)
        #expect(sut.state.currentAQI == 100)
    }

    // MARK: setCurrent

    @Test
    func setCurrent_geocodesAndAssignsToSlotA() async throws {
        let bundle = makeSUT()
        let sut = bundle.vm

        sut.send(.setCurrent)
        try await waitForLocation(sut, slot: .a)

        #expect(sut.state.locationA?.address == "Seoul, Gangnam-gu")
        #expect(bundle.cache.points.isEmpty == false) // cached on set
    }

    @Test
    func setCurrent_assignsToSlotBWhenAAlreadySet() async throws {
        let bundle = makeSUT()
        let sut = bundle.vm
        sut.send(.assignA(Self.makeSeoulA()))

        sut.send(.setCurrent)
        try await waitForLocation(sut, slot: .b)

        #expect(sut.state.locationB?.address == "Seoul, Gangnam-gu")
    }

    @Test
    func setCurrent_setsErrorMessage_whenGeocodeFails() async throws {
        let bundle = makeSUT()
        bundle.geocode.error = FakeError.canned
        let sut = bundle.vm

        sut.send(.setCurrent)
        try await waitForError(sut)

        #expect(sut.state.locationA == nil)
        #expect(sut.state.errorMessage != nil)
        #expect(sut.state.isLoading == false)
    }

    @Test
    func dismissError_clearsErrorMessage() async throws {
        let bundle = makeSUT()
        bundle.geocode.error = FakeError.canned
        let sut = bundle.vm

        sut.send(.setCurrent)
        try await waitForError(sut)

        sut.send(.dismissError)
        #expect(sut.state.errorMessage == nil)
    }

    // MARK: updateLocation - additional cases

    @Test
    func updateLocation_replacesB_whenIDMatchesB() {
        let sut = makeSUT().vm
        let b = Self.makeSeoulB()
        sut.send(.assignB(b))

        var renamed = b
        renamed.nickname = "office"
        sut.send(.updateLocation(renamed))

        #expect(sut.state.locationB?.nickname == "office")
        #expect(sut.state.locationA == nil)
    }

    @Test
    func updateLocation_ignoresUnmatchedID() {
        let sut = makeSUT().vm
        sut.send(.assignA(Self.makeSeoulA()))

        let stranger = LocationPoint(
            id: UUID(),
            latitude: 0, longitude: 0,
            aqi: 0, address: "Stranger", nickname: nil
        )
        sut.send(.updateLocation(stranger))

        // Nothing should have changed
        #expect(sut.state.locationA?.address == "Seoul, Gangnam-gu")
        #expect(sut.state.locationB == nil)
    }

    // MARK: SUT

    private struct SUT {
        let vm: MapViewModel
        let aqi: StubFetchAQIUseCase
        let geocode: StubReverseGeocodeUseCase
        let cache: InMemoryLocationCache
    }

    private func makeSUT(aqiResult: Int = 0) -> SUT {
        let aqi = StubFetchAQIUseCase(result: aqiResult)
        let geocode = StubReverseGeocodeUseCase(result: "Seoul, Gangnam-gu")
        let cache = InMemoryLocationCache()
        let vm = MapViewModel(
            fetchAQIUseCase: aqi,
            reverseGeocodeUseCase: geocode,
            cache: cache
        )
        return SUT(vm: vm, aqi: aqi, geocode: geocode, cache: cache)
    }

    // Static funcs (not computed properties) so each call produces a
    // FRESH LocationPoint that can be captured into a `let` and reused
    // across multiple #expects in the same test.
    private static func makeSeoulA() -> LocationPoint {
        LocationPoint(
            id: UUID(),
            latitude: 37.5642, longitude: 127.0016,
            aqi: 30, address: "Seoul, Gangnam-gu", nickname: nil
        )
    }

    private static func makeSeoulB() -> LocationPoint {
        LocationPoint(
            id: UUID(),
            latitude: 37.567, longitude: 127.0,
            aqi: 40, address: "Seoul, Jongno-gu", nickname: nil
        )
    }

    private static func coordEqual(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Bool {
        abs(a.latitude - b.latitude) < 1e-9 && abs(a.longitude - b.longitude) < 1e-9
    }

    // Polling helpers - state changes happen from a Task inside send(),
    // so we wait until the side effect lands or time out.
    private enum Slot { case a, b }

    private func waitForLocation(_ vm: MapViewModel, slot: Slot, timeoutMs: Int = 3_000) async throws {
        let deadline = Date().addingTimeInterval(Double(timeoutMs) / 1000)
        while Date() < deadline {
            switch slot {
            case .a: if vm.state.locationA != nil { return }
            case .b: if vm.state.locationB != nil { return }
            }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
    }

    private func waitForError(_ vm: MapViewModel, timeoutMs: Int = 3_000) async throws {
        let deadline = Date().addingTimeInterval(Double(timeoutMs) / 1000)
        while Date() < deadline {
            if vm.state.errorMessage != nil { return }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
    }
}

// MARK: Fakes

private final class StubFetchAQIUseCase: FetchAQIUseCaseProtocol {
    var result: Int
    private(set) var callCount = 0

    init(result: Int) { self.result = result }

    func execute(latitude: Double, longitude: Double) async throws -> Int {
        callCount += 1
        return result
    }

    func execute(coordinate: CLLocationCoordinate2D) async throws -> Int {
        try await execute(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}

private final class StubReverseGeocodeUseCase: ReverseGeocodeUseCaseProtocol {
    var result: String
    var error: Error?

    init(result: String) { self.result = result }

    func execute(latitude: Double, longitude: Double) async throws -> String {
        if let error { throw error }
        return result
    }

    func execute(coordinate: CLLocationCoordinate2D) async throws -> String {
        try await execute(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}

private final class InMemoryLocationCache: LocationCaching {
    fileprivate var points: [String: LocationPoint] = [:]
    private var addresses: [String: String] = [:]

    func save(location: LocationPoint) {
        let key = LocationCache.makeKey(latitude: location.latitude, longitude: location.longitude)
        points[key] = location
        addresses[key] = location.address
    }

    func saveAddress(latitude: Double, longitude: Double, address: String) {
        addresses[LocationCache.makeKey(latitude: latitude, longitude: longitude)] = address
    }

    func fetch(latitude: Double, longitude: Double) -> LocationPoint? {
        points[LocationCache.makeKey(latitude: latitude, longitude: longitude)]
    }

    func fetchAddress(latitude: Double, longitude: Double) -> String? {
        addresses[LocationCache.makeKey(latitude: latitude, longitude: longitude)]
    }

    func allLocations() -> [LocationPoint] { Array(points.values) }
}
