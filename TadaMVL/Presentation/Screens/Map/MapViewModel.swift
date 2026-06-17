import Foundation
import SwiftUI
import MapKit
import Combine

@MainActor
final class MapViewModel: ObservableObject {

    // MARK: State

    struct State {
        // Default region is roughly Seoul; gets overwritten as soon as we
        // get the first user-location fix or a history restore.
        var region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        var currentAQI: Int = 0
        // Bumped on every applied AQI response so the badge can re-animate
        // even when the value happens to be unchanged.
        var aqiResultEpoch: UInt64 = 0
        var locationA: LocationPoint?
        var locationB: LocationPoint?
        var isLoading: Bool = false
        var errorMessage: String?

        var bookingStep: BookingStep {
            if locationA == nil { return .setA }
            if locationB == nil { return .setB }
            return .book
        }
    }

    // MARK: Action

    enum Action {
        case centerOnUser(CLLocationCoordinate2D)   // first user fix
        case mapPanned(CLLocationCoordinate2D)      // pan/zoom from the map
        case regionChanged(MKCoordinateRegion)      // two-way region binding
        case setCurrent                             // V button (Set A / Set B)
        case assignA(LocationPoint)
        case assignB(LocationPoint)
        case updateLocation(LocationPoint)          // nickname edited
        case restore(Book)                          // history row tap
        case reset(recenterTo: CLLocationCoordinate2D?)
        case dismissError
    }

    @Published private(set) var state = State()

    // MARK: Dependencies

    private let fetchAQIUseCase: FetchAQIUseCaseProtocol
    private let reverseGeocodeUseCase: ReverseGeocodeUseCaseProtocol
    private let cache: LocationCaching

    // Debounce + cancellation plumbing for AQI fetches. Map panning fires
    // a lot of regionDidChange events; we want one network call per pause.
    private var aqiDebounceWorkItem: DispatchWorkItem?
    private var aqiFetchTask: Task<Void, Never>?
    private var aqiFetchGeneration: UInt64 = 0

    init(
        fetchAQIUseCase: FetchAQIUseCaseProtocol,
        reverseGeocodeUseCase: ReverseGeocodeUseCaseProtocol,
        cache: LocationCaching
    ) {
        self.fetchAQIUseCase = fetchAQIUseCase
        self.reverseGeocodeUseCase = reverseGeocodeUseCase
        self.cache = cache
    }

    // MARK: Send

    func send(_ action: Action) {
        switch action {
        case .centerOnUser(let coordinate):
            state.region = MKCoordinateRegion(center: coordinate, span: state.region.span)
            scheduleAQIFetch(at: coordinate)

        case .mapPanned(let coordinate):
            scheduleAQIFetch(at: coordinate)

        case .regionChanged(let region):
            state.region = region

        case .setCurrent:
            Task { await setCurrentLocation() }

        case .assignA(let point):
            state.locationA = point

        case .assignB(let point):
            state.locationB = point

        case .updateLocation(let updated):
            // We don't know up front whether the user edited A or B, so
            // match by id.
            if updated.id == state.locationA?.id { state.locationA = updated }
            if updated.id == state.locationB?.id { state.locationB = updated }

        case .restore(let book):
            state.locationA = book.a
            state.locationB = book.b
            let center = CLLocationCoordinate2D(
                latitude: book.a.latitude,
                longitude: book.a.longitude
            )
            state.region = MKCoordinateRegion(center: center, span: state.region.span)
            // AQI may have shifted since the booking - the brief explicitly
            // wants us to re-fetch on restore.
            scheduleAQIFetch(at: center)

        case .reset(let recenter):
            state.locationA = nil
            state.locationB = nil
            if let recenter {
                state.region = MKCoordinateRegion(center: recenter, span: state.region.span)
                scheduleAQIFetch(at: recenter)
            }

        case .dismissError:
            state.errorMessage = nil
        }
    }

    // Two-way binding for MKMapView's region. All writes still go through
    // `send(.regionChanged(...))` so the unidirectional contract holds.
    var regionBinding: Binding<MKCoordinateRegion> {
        Binding(
            get: { [unowned self] in self.state.region },
            set: { [unowned self] in self.send(.regionChanged($0)) }
        )
    }

    // MARK: Effects

    private func scheduleAQIFetch(at coordinate: CLLocationCoordinate2D) {
        aqiDebounceWorkItem?.cancel()

        // Capture as plain Doubles so the closure doesn't need to hop actors
        // just to read the coordinate fields.
        let lat = coordinate.latitude
        let lon = coordinate.longitude

        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.aqiFetchTask?.cancel()
            self.aqiFetchTask = Task { @MainActor in
                await self.fetchAQI(at: CLLocationCoordinate2D(latitude: lat, longitude: lon))
            }
        }
        aqiDebounceWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: work)
    }

    private func fetchAQI(at coordinate: CLLocationCoordinate2D) async {
        // Generation guard. If the user pans again while we're in flight,
        // the older response gets ignored when it eventually returns.
        aqiFetchGeneration += 1
        let generation = aqiFetchGeneration

        do {
            let aqi = try await fetchAQIUseCase.execute(coordinate: coordinate)
            guard generation == aqiFetchGeneration else { return }
            state.currentAQI = aqi
            state.aqiResultEpoch &+= 1
        } catch is CancellationError {
            return
        } catch {
            guard generation == aqiFetchGeneration else { return }
            state.errorMessage = error.localizedDescription
        }
    }

    private func setCurrentLocation() async {
        do {
            state.isLoading = true
            let center = state.region.center

            let address = try await reverseGeocodeUseCase.execute(coordinate: center)

            let point = LocationPoint(
                id: UUID(),
                latitude: center.latitude,
                longitude: center.longitude,
                aqi: state.currentAQI,
                address: address,
                nickname: nil
            )

            cache.save(location: point)

            switch state.bookingStep {
            case .setA: state.locationA = point
            case .setB: state.locationB = point
            case .book: break // shouldn't happen - V is "Book" then
            }

            state.isLoading = false
        } catch {
            state.isLoading = false
            state.errorMessage = error.localizedDescription
        }
    }
}
