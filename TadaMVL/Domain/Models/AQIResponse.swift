import Foundation

// WAQI feed response. We only care about data.aqi; the rest is ignored.
struct AQIResponse: Codable {
    let status: String
    let data: AQIData
}

struct AQIData: Codable {
    let aqi: Int
}
