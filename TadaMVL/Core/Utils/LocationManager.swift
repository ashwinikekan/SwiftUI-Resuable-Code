import Foundation
import CoreLocation
import Combine
import OSLog

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    @Published var location: CLLocationCoordinate2D?

    private let manager = CLLocationManager()
    private let log = Logger(subsystem: "com.tada.mvl", category: "location")

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestPermission() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()

        case .authorizedAlways, .authorizedWhenInUse:

            if let cached = manager.location?.coordinate {
                location = cached
            }
            manager.requestLocation()

        case .restricted, .denied:
            manager.stopUpdatingLocation()

        @unknown default:
            manager.stopUpdatingLocation()
        }
    }

    // MARK: CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            if let cached = manager.location?.coordinate {
                location = cached
            }
            manager.requestLocation()
        case .restricted, .denied:
            location = nil
            manager.stopUpdatingLocation()
        case .notDetermined:
            break
        @unknown default:
            manager.stopUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coord = locations.first?.coordinate else { return }
        location = coord
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {

        log.error("CoreLocation failed: \(error.localizedDescription, privacy: .public)")
    }
}
