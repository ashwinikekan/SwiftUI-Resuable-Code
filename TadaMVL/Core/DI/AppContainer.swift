import Foundation
import Combine

final class AppContainer: ObservableObject {

    let apiClient: APIClientProtocol
    let cache: LocationCaching

    // Repos are private; presentation layer talks to use-cases only.
    private let airQualityRepository: AirQualityRepository
    private let locationRepository: LocationRepository
    private let bookingRepository: BookingRepository

    let fetchAQIUseCase: FetchAQIUseCaseProtocol
    let reverseGeocodeUseCase: ReverseGeocodeUseCaseProtocol
    let createBookUseCase: CreateBookUseCaseProtocol
    let fetchBooksUseCase: FetchBooksUseCaseProtocol

    init() {
    
        let real = APIClientImpl()
        let useMock = ProcessInfo.processInfo.environment["DISABLE_MOCK_BOOKS"] != "1"
        self.apiClient = useMock ? MockAPIClient(passthrough: real) : real

        self.cache = LocationCache.shared

        let aqi = AQIServiceImpl(client: apiClient)
        let geocode = GeocodeServiceImpl(client: apiClient)

        self.airQualityRepository = AirQualityRepositoryImpl(service: aqi)
        self.locationRepository = LocationRepositoryImpl(service: geocode, cache: cache)
        self.bookingRepository = BookingRepositoryImpl(client: apiClient)

        self.fetchAQIUseCase = FetchAQIUseCase(repository: airQualityRepository)
        self.reverseGeocodeUseCase = ReverseGeocodeUseCase(repository: locationRepository)
        self.createBookUseCase = CreateBookUseCase(repository: bookingRepository)
        self.fetchBooksUseCase = FetchBooksUseCase(repository: bookingRepository)
    }
}
