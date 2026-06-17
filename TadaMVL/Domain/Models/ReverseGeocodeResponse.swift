import Foundation

struct ReverseGeocodeResponse: Codable, Equatable {
    let localityInfo: LocalityInfo
}

struct LocalityInfo: Codable, Equatable {
    let administrative: [AdministrativeArea]
}

struct AdministrativeArea: Codable, Equatable {
    let name: String
    let order: Int
}

extension ReverseGeocodeResponse {

    // Take the two highest-order administrative entries (most specific
    // levels) and join with ", ". The brief calls for this exact behavior.
    // Lives on the response type so we can unit test the sorting without
    // stubbing the network layer.
    var topTwoAddressNames: String {
        localityInfo.administrative
            .sorted { $0.order > $1.order }
            .prefix(2)
            .map(\.name)
            .joined(separator: ", ")
    }
}
