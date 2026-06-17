import Foundation

enum APIConstants {
    static let aqiToken: String = {
        if let t = Bundle.main.object(forInfoDictionaryKey: "AQI_TOKEN") as? String,
           !t.isEmpty {
            return t
        }
        return "6149975db1e6c9b112e776fe6c520ea5061ab767"
    }()

    static let aqiBaseURL = "https://api.waqi.info"
    static let geocodeBaseURL = "https://api.bigdatacloud.net"
    static let bookingBaseURL = "https://mock.tada.local"
}
