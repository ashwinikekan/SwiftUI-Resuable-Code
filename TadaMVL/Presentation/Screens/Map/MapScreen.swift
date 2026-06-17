import SwiftUI
import MapKit

struct MapScreen: View {

    @EnvironmentObject private var container: AppContainer

    @StateObject private var locationManager = LocationManager()
    @StateObject private var viewModel: MapViewModel

    // Pure UI state. Business state lives in the view model.
    @State private var path: [MapRoute] = []
    @State private var showCachedA = false
    @State private var showCachedB = false
    @State private var hasCenteredOnUser = false

    init(container: AppContainer) {
        _viewModel = StateObject(
            wrappedValue: MapViewModel(
                fetchAQIUseCase: container.fetchAQIUseCase,
                reverseGeocodeUseCase: container.reverseGeocodeUseCase,
                cache: container.cache
            )
        )
    }

    var body: some View {

        NavigationStack(path: $path) {

            ZStack(alignment: .top) {
                ZStack {
                    mapView
                    CenterMarkerView()
                    topAQIView
                    bottomView
                }
                .ignoresSafeArea(edges: [.top, .leading, .trailing])

                if let message = viewModel.state.errorMessage {
                    ErrorBanner(message: message) {
                        viewModel.send(.dismissError)
                    }
                    .padding(.top, DesignTokens.Spacing.xs)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
                }
            }
            .animation(.spring(response: 0.35), value: viewModel.state.errorMessage)
            .animation(.spring(response: 0.35), value: viewModel.state.locationA)
            .animation(.spring(response: 0.35), value: viewModel.state.locationB)
            .task {
                locationManager.requestPermission()
            }
            .onReceive(locationManager.$location) { coordinate in
                // Only recenter on the FIRST fix - otherwise we'd snap the
                // map away from wherever the user just panned to.
                guard let coordinate, !hasCenteredOnUser else { return }
                hasCenteredOnUser = true
                viewModel.send(.centerOnUser(coordinate))
            }
            .navigationDestination(for: MapRoute.self) { route in
                destination(for: route)
            }
            .sheet(isPresented: $showCachedA) {
                NavigationStack {
                    CachedLocationsScreen { location in
                        viewModel.send(.assignA(location))
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                }
            }
            .sheet(isPresented: $showCachedB) {
                NavigationStack {
                    CachedLocationsScreen { location in
                        viewModel.send(.assignB(location))
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                }
            }
        }
    }
}

// MARK: Navigation

private extension MapScreen {

    @ViewBuilder
    func destination(for route: MapRoute) -> some View {
        switch route {
        case .detail(let slot, let location):
            LocationDetailScreen(slot: slot, location: location) { updated in
                viewModel.send(.updateLocation(updated))
            }

        case .booking:
            if let a = viewModel.state.locationA, let b = viewModel.state.locationB {
                BookingScreen(
                    container: container,
                    a: a, b: b,
                    path: $path,
                    onBack: handleReset
                )
            }

        case .history:
            HistoryScreen(
                container: container,
                onRowTap: handleRestore,
                onClose: handleReset
            )
        }
    }

    func handleRestore(_ book: Book) {
        path.removeAll()
        viewModel.send(.restore(book))
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    // Back/Close from a pushed screen returns to Map with state cleared,
    // again per the brief.
    func handleReset() {
        path.removeAll()
        viewModel.send(.reset(recenterTo: locationManager.location))
    }
}

// MARK: Subviews

private extension MapScreen {

    var mapView: some View {
        MKMapContainerView(
            region: viewModel.regionBinding,
            showsUserLocation: true,
            onMapCenterChanged: { coordinate in
                viewModel.send(.mapPanned(coordinate))
            }
        )
    }

    var topAQIView: some View {
        VStack {
            HStack {
                Spacer()
                AQIBadgeView(aqi: viewModel.state.currentAQI)
                    .id(viewModel.state.aqiResultEpoch)
                    .transition(.scale.combined(with: .opacity))
            }
            Spacer()
        }
        .padding(.top, 60)
        .padding(.trailing, DesignTokens.Spacing.lg)
    }

    var bottomView: some View {
        VStack {
            Spacer()
            BottomActionView(
                locationA: viewModel.state.locationA,
                locationB: viewModel.state.locationB,
                buttonTitle: viewModel.state.bookingStep.buttonTitle,
                onALocationTap: {
                    // Slot set -> open detail. Slot empty -> open the
                    // cached-locations sheet (5th screen).
                    if let a = viewModel.state.locationA {
                        path.append(.detail(slot: "A", location: a))
                    } else {
                        showCachedA = true
                    }
                },
                onBLocationTap: {
                    if let b = viewModel.state.locationB {
                        path.append(.detail(slot: "B", location: b))
                    } else {
                        showCachedB = true
                    }
                },
                onButtonTap: {
                    switch viewModel.state.bookingStep {
                    case .setA, .setB:
                        viewModel.send(.setCurrent)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    case .book:
                        path.append(.booking)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                }
            )
        }
    }
}
