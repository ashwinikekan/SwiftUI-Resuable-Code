import Foundation

// Cache abstraction so tests can swap in an in-memory fake.
protocol LocationCaching {
    func save(location: LocationPoint)
    func saveAddress(latitude: Double, longitude: Double, address: String)
    func fetch(latitude: Double, longitude: Double) -> LocationPoint?
    func fetchAddress(latitude: Double, longitude: Double) -> String?
    func allLocations() -> [LocationPoint]
}

final class LocationCache: LocationCaching {

    static let shared = LocationCache()

    private let pointStorageKey   = "cached_locations"
    private let addressStorageKey = "cached_addresses"

    private var pointCache:   [String: LocationPoint] = [:]
    private var addressCache: [String: String] = [:]

    private let queue = DispatchQueue(
        label: "com.tada.mvl.location-cache",
        attributes: .concurrent
    )

    private let defaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.defaults = userDefaults
        load()
    }

    // MARK: Writes

    func save(location: LocationPoint) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self else { return }
            let key = Self.makeKey(latitude: location.latitude, longitude: location.longitude)
            pointCache[key] = location
            addressCache[key] = location.address
            persistPoints()
            persistAddresses()
        }
    }

    func saveAddress(latitude: Double, longitude: Double, address: String) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self else { return }
            addressCache[Self.makeKey(latitude: latitude, longitude: longitude)] = address
            persistAddresses()
        }
    }

    // MARK: Reads

    func fetch(latitude: Double, longitude: Double) -> LocationPoint? {
        queue.sync { pointCache[Self.makeKey(latitude: latitude, longitude: longitude)] }
    }

    func fetchAddress(latitude: Double, longitude: Double) -> String? {
        queue.sync { addressCache[Self.makeKey(latitude: latitude, longitude: longitude)] }
    }

    func allLocations() -> [LocationPoint] {
        queue.sync { Array(pointCache.values) }
    }

    static func makeKey(latitude: Double, longitude: Double) -> String {
        "\(latitude.truncatedTo3())_\(longitude.truncatedTo3())"
    }

    // MARK: Persistence

    private func persistPoints() {
        do {
            defaults.set(try JSONEncoder().encode(pointCache), forKey: pointStorageKey)
        } catch {
            assertionFailure("Failed to persist points: \(error)")
        }
    }

    private func persistAddresses() {
        do {
            defaults.set(try JSONEncoder().encode(addressCache), forKey: addressStorageKey)
        } catch {
            assertionFailure("Failed to persist addresses: \(error)")
        }
    }

    private func load() {
        if let data = defaults.data(forKey: pointStorageKey),
           let decoded = try? JSONDecoder().decode([String: LocationPoint].self, from: data) {
            pointCache = decoded
        }
        if let data = defaults.data(forKey: addressStorageKey),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            addressCache = decoded
        }
    }
}
