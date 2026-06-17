import Foundation

struct LocationPoint: Codable, Identifiable, Equatable, Hashable {

    let id: UUID
    let latitude: Double
    let longitude: Double
    let aqi: Int
    let address: String
    var nickname: String?

    // What the UI should render. Nickname wins if the user set one,
    // otherwise we fall back to the raw geocoded address.
    var displayName: String {
        if let n = nickname, !n.isEmpty { return n }
        return address
    }
}
