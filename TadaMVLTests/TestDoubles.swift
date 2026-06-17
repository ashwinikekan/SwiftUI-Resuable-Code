import Foundation
import Alamofire
@testable import TadaMVL


final class FakeAPIClient: APIClientProtocol {

    enum Call: Equatable {
        case parameters(url: String, method: String, params: [String: String])
        case body(url: String, method: String, body: Data?)
    }

    var recordedCalls: [Call] = []
    var paramResponse: (Any)? = nil
    var bodyResponse: (Any)? = nil
    var errorToThrow: Error?

    init(
        paramResponse: Any? = nil,
        bodyResponse: Any? = nil,
        errorToThrow: Error? = nil
    ) {
        self.paramResponse = paramResponse
        self.bodyResponse = bodyResponse
        self.errorToThrow = errorToThrow
    }

    func request<T: Decodable>(
        _ url: String,
        method: HTTPMethod,
        parameters: Parameters?
    ) async throws -> T {
        // Stringify params so we don't have to depend on Any equality.
        var dict: [String: String] = [:]
        for (k, v) in (parameters ?? [:]) {
            dict[k] = "\(v)"
        }
        recordedCalls.append(.parameters(url: url, method: method.rawValue, params: dict))

        if let errorToThrow { throw errorToThrow }
        guard let value = paramResponse as? T else {
            throw FakeError.noResponseConfigured
        }
        return value
    }

    func request<Body: Encodable, T: Decodable>(
        _ url: String,
        method: HTTPMethod,
        body: Body
    ) async throws -> T {
        let data = try? JSONEncoder().encode(body)
        recordedCalls.append(.body(url: url, method: method.rawValue, body: data))

        if let errorToThrow { throw errorToThrow }
        guard let value = bodyResponse as? T else {
            throw FakeError.noResponseConfigured
        }
        return value
    }
}

// MARK: Geocode + AQI service fakes

final class FakeGeocodeService: GeocodeServiceProtocol {
    var calls: [(lat: Double, lon: Double)] = []
    var result: String = ""
    var error: Error?

    func reverseGeocode(latitude: Double, longitude: Double) async throws -> String {
        calls.append((latitude, longitude))
        if let error { throw error }
        return result
    }
}

final class FakeAQIService: AQIServiceProtocol {
    var calls: [(lat: Double, lon: Double)] = []
    var result: Int = 0
    var error: Error?

    func fetchAQI(latitude: Double, longitude: Double) async throws -> Int {
        calls.append((latitude, longitude))
        if let error { throw error }
        return result
    }
}

// MARK: LocationCaching fake

final class FakeLocationCache: LocationCaching {

    private(set) var points: [String: LocationPoint] = [:]
    private(set) var addresses: [String: String] = [:]

    private(set) var saveCount = 0
    private(set) var saveAddressCount = 0

    func save(location: LocationPoint) {
        saveCount += 1
        let key = LocationCache.makeKey(latitude: location.latitude, longitude: location.longitude)
        points[key] = location
    }

    func saveAddress(latitude: Double, longitude: Double, address: String) {
        saveAddressCount += 1
        let key = LocationCache.makeKey(latitude: latitude, longitude: longitude)
        addresses[key] = address
    }

    func fetch(latitude: Double, longitude: Double) -> LocationPoint? {
        points[LocationCache.makeKey(latitude: latitude, longitude: longitude)]
    }

    func fetchAddress(latitude: Double, longitude: Double) -> String? {
        addresses[LocationCache.makeKey(latitude: latitude, longitude: longitude)]
    }

    func allLocations() -> [LocationPoint] {
        Array(points.values)
    }

    // Seed helper - lets tests preload data without round-tripping through
    // the save methods (which would bump the counters).
    func preload(address: String, lat: Double, lon: Double) {
        addresses[LocationCache.makeKey(latitude: lat, longitude: lon)] = address
    }
}

// MARK: Errors

enum FakeError: Error, Equatable {
    case noResponseConfigured
    case canned
}
